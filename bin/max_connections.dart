import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:convert';

main() async {
  List<WebSocket> connections = new List<WebSocket>();

  for(int i = 0; i < 10000; i++) {
    sleep(const Duration(milliseconds: 20));

    await WebSocket.connect('wss://telephonist.tk/telephonist').then((WebSocket connection) {
      connections.add(connection);
      print('Connection has been established.');

      String id;
      DateTime start;

      connection.listen((data) {

        Map message = JSON.decode(data);

        if (message['type'] == 'peers') {
          id = message['you'];
          start = new DateTime.now();
          print(id);

//          connection.add(JSON.encode({
//            'type': 'candidate',
//            'id': id
//          }));
        } if (message['type'] == 'candidate')  {
//          print(data);
//          DateTime end = new DateTime.now();
//          print(end.difference(start));
        }
      });

      connection.add(JSON.encode({
        'type': 'join',
        'room': 'max_connections_${id}_${new DateTime.now()}'
      }));
    });
  }

  for(WebSocket connection in connections) {
    print(new DateTime.now());
    await connection.close();
    sleep(const Duration(milliseconds: 300));
  }
}