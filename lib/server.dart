library telephonist_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

/**
 * Сигнальный сервер для WebRTC.
 */
class TelephonistServer {
  /*
   * Нужно убрать эту херню или сделать опциональное создание собственного HTTP-сервера.
   */
  HttpServer _server;

  /**
   * Набор socket.hashCode и соответсвующих им сокетов.
   */
  var _sockets = new Map<int, WebSocket>();
  
  /**
   * Набор идентификатов комнат и хэшей сокетов их участников.
   */
  var _rooms = new Map<String, List<int>>();

  /**
   * Через этот контроллер мы отправляем сообщения подписчикам.
   */
  var _messageController = new StreamController();
  
  /**
   * Из этого потока подписчики читают наши сообщения.
   */
  Stream _messages;

  TelephonistServer() {
    // Получаем поток, на который можно подписаться множество раз.
    _messages = _messageController.stream.asBroadcastStream();

    onJoin.listen((message) {
      var socket = message['_socket'];

      // Если в комнате никого нет, то создаем её.
      if (_rooms[message['room']] == null) {
        _rooms[message['room']] = new List<int>();
      }

      // Рассылаем всем участникам комнаты уведомление о появлении нового пользователя в комнате.
      _rooms[message['room']].forEach((client) {
        _sockets[client].add(JSON.encode({
          'type': 'new',
          'id': socket.hashCode
        }));
      });

      // Отправляем новому пользователю список пользовтелей в комнате и его собственный идентификатор.
      socket.add(JSON.encode({
        'type': 'peers',
        'connections': _rooms[message['room']],
        'you': socket.hashCode
      }));

      // Добавляем нового пользовтеля в комнату.
      _rooms[message['room']].add(socket.hashCode);
    });

    onOffer.listen((message) {
      var socket = message['_socket'];

      // Сокет собеседника, которомы мы отправляем предложение на установку соединения.
      var soc = _sockets[message['id']];

      // Отрпавляем предложение на установку соединения.
      soc.add(JSON.encode({
        'type': 'offer',
        'description': message['description'],
        'id': socket.hashCode
      }));
    });

    onAnswer.listen((message) {
      var socket = message['_socket'];

      // Сокет собеседника, которому мы отправляем ответ на предложение об установке соединения.
      var soc = _sockets[message['id']];

      // Отправляем ответ.
      soc.add(JSON.encode({
        'type': 'answer',
        'description': message['description'],
        'id': socket.hashCode
      }));
    });

    onCandidate.listen((message) {
      var socket = message['_socket'];

      var soc = _sockets[message['id']];

      soc.add(JSON.encode({
        'type': 'candidate',
        'label': message['label'],
        'candidate': message['candidate'],
        'id': socket.hashCode
      }));
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
        _sockets[socket.hashCode] = socket;

        socket.listen((m) {
          var message = JSON.decode(m);
          message['_socket'] = socket;
          _messageController.add(message);
        },
        onDone: () {
          int id = socket.hashCode;
          _sockets.remove(id);

          _rooms.forEach((room, clients) {
            if (clients.contains(id)) {
              clients.remove(id);

              clients.forEach((client) {
                _sockets[client].add(JSON.encode({
                  'type': 'leave',
                  'id': id
                }));
              });
            }
          });
        });
      });

      return this;
    });
  }
}