library telephonist_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:redis_client/redis_client.dart';
import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" as Stomp;

/**
 * Сигнальный сервер для WebRTC.
 */
class TelephonistServer {
  String id;
  RedisClient redisClient;
  StompClient stompClient;
  
  /*
   * Нужно убрать эту херню или сделать опциональное создание собственного HTTP-сервера.
   */
  HttpServer _server;

  /**
   * ID сокета -> cокет.
   */
  var _sockets = new Map<String, WebSocket>();
  
  /**
   * Через этот контроллер мы отправляем сообщения подписчикам.
   */
  var _messageController = new StreamController();
  
  /**
   * Из этого потока подписчики читают наши сообщения.
   */
  Stream _messages;

  TelephonistServer({this.id, this.redisClient, this.stompClient}) {
    // Получаем поток, на который можно подписаться множество раз.
    _messages = _messageController.stream.asBroadcastStream();
    
    stompClient.subscribeJson('0', '/' + this.id,
      (Map<String, String> headers, Object message) {
        print("Recieve $message");
        WebSocket socket = _sockets[message['destination']];
        if (socket != null) socket.add(message['data']);
      }
    );

    onJoin.listen((message) {
      WebSocket socket = message['_socket'];

      redisClient.smembers('room:' + message['room']).then((Set<String> sockets) {
        var newMessage = {'type': 'new', 'id': this.id + ':' + socket.hashCode.toString()};
        
        newMessage = JSON.encode(newMessage);
        
        sockets.forEach((String socketId) {
          String serverId = socketId.split(':').first;
          stompClient.sendJson('/' + serverId, {'destination': socketId, 'data': newMessage});
        });
        
        socket.add(JSON.encode({
          'type': 'peers',
          'connections': sockets.toList(),
          'you': this.id + ':' + socket.hashCode.toString()
        }));
      });

      redisClient.sadd('room:' + message['room'], this.id + ':' + socket.hashCode.toString());
      redisClient.sadd(this.id + ':' + socket.hashCode.toString(), message['room']);
    });

    onOffer.listen((message) {
      var socket = message['_socket'];

      String serverId = message['id'].split(':').first;
      
      var newMessage = {
        'type': 'offer',
        'description': message['description'],
        'id': this.id + ':' + socket.hashCode.toString()
       };
      
      newMessage = JSON.encode(newMessage);
      
      stompClient.sendJson('/' + serverId, {'destination': message['id'], 'data': newMessage});
    });

    onAnswer.listen((message) {
      var socket = message['_socket'];

      String serverId = message['id'].split(':').first;
      
      var newMessage = {
        'type': 'answer',
        'description': message['description'],
        'id': this.id + ':' + socket.hashCode.toString()
      };
      
      newMessage = JSON.encode(newMessage);
      
      stompClient.sendJson('/' + serverId, {'destination': message['id'], 'data': newMessage});
    });

    onCandidate.listen((message) {
      var socket = message['_socket'];

      String serverId = message['id'].split(':').first;

      var newMessage = {
        'type': 'candidate',
        'label': message['label'],
        'candidate': message['candidate'],
        'id': this.id + ':' + socket.hashCode.toString()
      };
      
      newMessage = JSON.encode(newMessage);
      
      stompClient.sendJson('/' + serverId, {'destination': message['id'], 'data': newMessage});
    });
  }

  /**
   * Новый пользователь присоединился.
   */
  get onJoin => _messages.where((m) => m['type'] == 'join');

  /**
   * Предложение к установлению соединения.
   */
  get onOffer => _messages.where((m) => m['type'] == 'offer');

  /**
   * Ответ на предложение установления соединения.
   */
  get onAnswer => _messages.where((m) => m['type'] == 'answer');

  /**
   * Данные для установления соединения.
   */
  get onCandidate => _messages.where((m) => m['type'] == 'candidate');

  Future<TelephonistServer> listen(String host, num port) {
    return HttpServer.bind(host, port).then((HttpServer server) {
      _server = server;

      _server.transform(new WebSocketTransformer()).listen((WebSocket socket) {
        _sockets[this.id + ':' + socket.hashCode.toString()] = socket;

        socket.listen((m) {
          var message = JSON.decode(m);
          message['_socket'] = socket;
          _messageController.add(message);
        },
        onDone: () {
          var id = this.id + ':' + socket.hashCode.toString();
          _sockets.remove(id);

          redisClient.smembers(id)
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.srem('room:' + room.toString(), id))))
          .then((_) => redisClient.smembers(id))
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.smembers('room:' + room.toString()))))
          .then((soketsIdsOfRoom) {
            soketsIdsOfRoom.forEach((socketsIds) => socketsIds.forEach((socketId) {
              String serverId = socketId.split(':').first;  
              
              var data = JSON.encode({
                'type': 'leave',
                'id': id
              });
              
              stompClient.sendJson('/' + serverId, {'destination': socketId, 'data': data}); 
            }));
          })
          .then((_) => redisClient.del(id));
        });
      });

      return this;
    });
  }
}