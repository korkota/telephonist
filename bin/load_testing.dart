import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:convert';

main() {
  WebSocket.connect('wss://telephonist.tk/telephonist').then((WebSocket connection) {
    print('Connection has been established.');

    String id;
    int counter = 0;
    DateTime start;

    connection.listen((data) {
      Map message = JSON.decode(data);

      if (message['type'] == 'peers') {
        id = message['you'];


        start = new DateTime.now();
        var timer = new Timer.periodic(new Duration(microseconds: 3000), (Timer timer) {

          for(int i = 0; i < 1; i++) {
            connection.add(JSON.encode({
              'type': 'candidate',
              'id': id
            }));
          }

        });
      } else {
        counter++;
        //print(counter);

        if (counter == 1000) {
          DateTime end =  new DateTime.now();
          print(end.difference(start));
        }
      }
    });

    connection.add(JSON.encode({
      'type': 'join',
      'room': 'load_testing'
    }));

  });
}