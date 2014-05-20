import 'dart:async';

import 'package:telephonist/server.dart';
import 'package:telephonist/redis_client.dart';
import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" as Stomp;

void main() {
  Future.wait([Stomp.connect('127.0.0.1', port: 10000), Stomp.connect('127.0.0.1', port: 10001)])
    .then((List<StompClient> stompClients) {
      RedisClient redisClient = new RedisClient(host: '192.168.2.101', port: 12000);
      TelephonistServer ts = new TelephonistServer(id: 'testId', redisClient: redisClient, stompClients: stompClients)..listen('127.0.0.1', 3000);
    });
}
