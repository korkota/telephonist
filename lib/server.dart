library telephonist_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:telephonist/telephonist_util.dart';
import 'package:telephonist/redis_client.dart';
import 'package:telephonist/stomp_clients.dart';

/**
 * Сигнальный сервер для WebRTC.
 */
class TelephonistServer {
  /// Идентификатор сигнального сервера.
  String id;

  int _connectionsCounter = 0;

  /// Клиент для доступа к общим данным.
  RedisClient redisClient;
  
  /// Клиенты для очередей сообщений.
  StompClients stompClients;
  
  /// Сервер, к которому подключаются клиенты.
  HttpServer _server;

  /// Список сокетов, подключенных к серверу.
  Map<String, WebSocket> _sockets = new Map<String, WebSocket>();

  Map<WebSocket, String> _ids = new Map<WebSocket, String>();
  
  /// Контроллер для отправки сообщений подписчикам.
  StreamController _messageController = new StreamController();
  
  /// Поток сообщений для подписчиков.
  Stream _messages;

  TelephonistServer({this.id, this.redisClient, this.stompClients}) {
    // Получаем поток, на который можно подписаться множество раз.
    _messages = _messageController.stream.asBroadcastStream();
    
    // Подписываемся на прием сообщений от других серверов.
    stompClients.subscribeJson(id, '/${id}', _onStompMessage);

    onJoin.listen((message) {
      if (message['room'] == null) return;
      
      WebSocket socket = message['_socket'];

      redisClient.smembers('room:' + message['room']).then((Set<String> sockets) {
        var newMessage = {
          'type': 'new', 
          'id': this.id + ':' + _ids[socket]
        };
        
        newMessage = JSON.encode(newMessage);
        
        sockets.map((String socketId) => new SocketId(socketId)).forEach((SocketId socketId) {
          stompClients.sendJson("/${socketId.serverId}", {
            'destination': socketId.toString(), 
            'data': newMessage
            });
        });
        
        var peersMessage = JSON.encode({
          'type': 'peers',
          'connections': sockets.toList(),
          'you': this.id + ':' + _ids[socket]
        });
        
        print(peersMessage.toString());
        
        socket.add(peersMessage);
      });

      redisClient.sadd('room:' + message['room'], this.id + ':' + _ids[socket]);
      redisClient.sadd(this.id + ':' + _ids[socket], message['room']);
    });

    onOffer.listen((message) {
      var socket = message['_socket'];

      SocketId socketId = new SocketId(message['id']);
      
      var newMessage = {
        'type': 'offer',
        'description': message['description'],
        'id': this.id + ':' + _ids[socket]
       };
      
      newMessage = JSON.encode(newMessage);
      
      stompClients.sendJson('/${socketId.serverId}', {
        'destination': socketId.toString(), 
        'data': newMessage
      });
    });

    onAnswer.listen((message) {
      var socket = message['_socket'];

      SocketId socketId = new SocketId(message['id']);
      
      var newMessage = {
        'type': 'answer',
        'description': message['description'],
        'id': this.id + ':' + _ids[socket]
      };
      
      newMessage = JSON.encode(newMessage);
      
      stompClients.sendJson('/${socketId.serverId}', {
        'destination': message['id'], 
        'data': newMessage
      });
    });

    onCandidate.listen((message) {
      var socket = message['_socket'];

      SocketId socketId = new SocketId(message['id']);

      var newMessage = {
        'type': 'candidate',
        'label': message['label'],
        'candidate': message['candidate'],
        'id': this.id + ':' + _ids[socket]
      };
      
      newMessage = JSON.encode(newMessage);
      
      stompClients..sendJson('/${socketId.serverId}', {
        'destination': message['id'], 
        'data': newMessage
      });
    });
  }

  void _onStompMessage(Map<String, String> headers, Object message) {
    print("Server ${id} has got message: $message");
    WebSocket socket = _sockets[message['destination']];
    if (socket != null) {
      socket.add(message['data']);
    } else {
      print('Wrong destination!');
    }
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
    return HttpServer.bind(host, port, shared: true).then((HttpServer server) {
      _server = server;

      _server.transform(new WebSocketTransformer()).listen((WebSocket socket) {
        _connectionsCounter++;
        _ids[socket] = _connectionsCounter.toString();
        _sockets[this.id + ':' + _ids[socket]] = socket;

        socket.listen((m) {
          print("Recieve $m");
          var message = JSON.decode(m);
          message['_socket'] = socket;
          _messageController.add(message);
        },
        onDone: () {
          var id = this.id + ':' + _ids[socket];
          _sockets.remove(id);
          _ids.remove(socket);

          redisClient.smembers(id)
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.srem('room:' + room.toString(), id))))
          .then((_) => redisClient.smembers(id))
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.smembers('room:' + room.toString()))))
          .then((soketsIdsOfRoom) {
            soketsIdsOfRoom.forEach((socketsIds) => socketsIds.map((String id) => new SocketId(id)).forEach((SocketId socketId) {             
              var data = JSON.encode({
                'type': 'leave',
                'id': id
              });
              
              stompClients.sendJson('/${socketId.serverId}', {
                'destination': socketId.toString(), 
                'data': data
              }); 
            }));
          })
          .then((_) => redisClient.del(id));
        });
      });

      return this;
    });
  }
}