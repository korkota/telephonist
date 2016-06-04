library telephonist_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

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

  final Logger _log = new Logger('server');

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
          'id': buildGlobalId(id, _ids[socket])
        };
        
        newMessage = JSON.encode(newMessage);
        
        sockets.map((String socketId) => new SocketId(socketId)).forEach((SocketId socketId) {
          stompClients.sendJson("/${socketId.serverId}", {
            'destination': socketId.toString(), 
            'data': newMessage
            });
        });
        
        var peersMessage = {
          'type': 'peers',
          'connections': sockets.toList(),
          'you': buildGlobalId(id, _ids[socket])
        };

        _log.info("has sent the message to the connection #${peersMessage['you']}:\n${prettyJson(peersMessage)}");
        
        socket.add(JSON.encode(peersMessage));
      });

      redisClient.sadd('room:' + message['room'], buildGlobalId(id, _ids[socket]));
      redisClient.sadd(buildGlobalId(id, _ids[socket]), message['room']);
    });

    onOffer.listen((message) {
      var socket = message['_socket'];

      SocketId socketId = new SocketId(message['id']);
      
      var newMessage = {
        'type': 'offer',
        'description': message['description'],
        'id': buildGlobalId(id, _ids[socket])
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
        'id': buildGlobalId(id, _ids[socket])
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
        'id': buildGlobalId(id, _ids[socket])
      };
      
      newMessage = JSON.encode(newMessage);
      
      stompClients..sendJson('/${socketId.serverId}', {
        'destination': message['id'], 
        'data': newMessage
      });
    });
  }

  void _onStompMessage(Map<String, String> headers, Object message) {
    WebSocket socket = _sockets[message['destination']];
    String prettyMessage = prettyJson(JSON.decode(message['data']));

    _log.info('has got the message from brocker:\n${prettyJson(message)}');

    if (socket != null) {
      _log.info('has got the message from brocker and has sent it to connection #${message['destination']}:\n$prettyMessage');
      socket.add(message['data']);
    } else {
      _log.warning('has got the message with the wrong destionation:\n$prettyMessage');
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
      _log.info('has been launched on $host:$port.');

      _server = server;

      _server.transform(new WebSocketTransformer()).listen((WebSocket socket) {
        _connectionsCounter++;
        _log.info('has got the new connection #$_connectionsCounter.');

        _ids[socket] = _connectionsCounter.toString();
        _sockets[buildGlobalId(id, _ids[socket])] = socket;

        socket.listen((String serializedMessage) {
          Map message = JSON.decode(serializedMessage);
          _log.info('has got the message from the connection #${_ids[socket]}:\n${prettyJson(message)}');
          message['_socket'] = socket;
          _messageController.add(message);
        },
        onDone: () {
          _log.info('has lost the conntection #${_ids[socket]} to the client.');

          String globalId = buildGlobalId(id, _ids[socket]);
          _sockets.remove(globalId);
          _ids.remove(socket);

          redisClient.smembers(globalId)
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.srem('room:' + room.toString(), globalId))))
          .then((_) => redisClient.smembers(globalId))
          .then((Set<String> rooms) => Future.wait(rooms.map((room) => redisClient.smembers('room:' + room.toString()))))
          .then((soketsIdsOfRoom) {
            soketsIdsOfRoom.forEach((socketsIds) => socketsIds.map((String id) => new SocketId(id)).forEach((SocketId socketId) {             
              String data = JSON.encode({
                'type': 'leave',
                'id': globalId
              });

              Map message = {
                'destination': socketId.toString(),
                'data': data
              };

              stompClients.sendJson('/${socketId.serverId}', message);
            }));
          })
          .then((_) => redisClient.del(globalId));
        });
      });

      return this;
    });
  }
}