import 'dart:async';
import 'dart:isolate';

import 'package:telephonist/server.dart';
import 'package:telephonist/redis_client.dart';
import 'package:telephonist/stomp_clients.dart';
import 'package:telephonist/telephonist_util.dart';
import 'package:telephonist/args_parser.dart';

main(List<String> args) async {
  Map config = parseArgs(args);

  for (int workerId = 0; workerId < config['threads']; workerId++) {
    config['id'] = 'isolate' + workerId.toString();
    await Isolate.spawn(worker, config);
  }

  while (true);
}

worker(Map config) async {
  List<HostAndPort> hostsAndPorts = [
    new HostAndPort('127.0.0.1', 61613)
  ];

  StompClients stompClients = new StompClients(hostsAndPorts);

  stompClients.connect(login: 'admin', password: 'password').then((StompClients stompClients) {
    RedisClient redisClient = new RedisClient(host: '127.0.0.1', port: 12000);
    TelephonistServer ts = new TelephonistServer(
      id: config['id'],
      redisClient: redisClient,
      stompClients: stompClients
    )..listen(config['host'], config['port']);
  });
}
