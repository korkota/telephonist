import 'dart:async';

import 'package:telephonist/server.dart';
import 'package:redis_client/redis_client.dart';
import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" as Stomp;

void main() {
  Future.wait([RedisClient.connect('127.0.0.1:6379'), Stomp.connect('127.0.0.1', port: 10000)])
  .then((clients) {
    TelephonistServer ts = new TelephonistServer(id: 'testId', redisClient: clients[0], stompClient: clients[1])..listen('127.0.0.1', 3000);
  });
}

//void main() {
//  .then((StompClient client) {
//    client.subscribeString("0", "/foo",
//      (Map<String, String> headers, String message) {
//        print("Recieve $message");
//      });
//
//    client.sendString("/foo", "Hi, Stomp");
//  });
//}
//
//.then((RedisClient redisClient) {
//  TelephonistServer ts = new TelephonistServer(id: 'testId', redisClient: redisClient)..listen('127.0.0.1', 3000);
//  // Use your client here. Eg.:
//  client.set("test", "value")
//      .then((_) => client.get("test"))
//      .then((value) => print("success: $value"));
//});