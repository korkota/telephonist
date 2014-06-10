import 'dart:async';

import 'package:telephonist/server.dart';
import 'package:telephonist/redis_client.dart';
import 'package:telephonist/stomp_clients.dart';
import 'package:telephonist/telephonist_util.dart';

void main() {
  List<HostAndPort> hostsAndPorts = [new HostAndPort('127.0.0.1', 10000), new HostAndPort('127.0.0.1', 10000)];
  StompClients stompClients = new StompClients(hostsAndPorts);
  
  stompClients.connect()
    .then((StompClients stompClients) {
      RedisClient redisClient = new RedisClient(host: '192.168.2.101', port: 12000);
      TelephonistServer ts = new TelephonistServer(id: 'testId', redisClient: redisClient, stompClients: stompClients)..listen('127.0.0.1', 3000);
    });
}
