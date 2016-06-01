import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';

import 'package:telephonist/server.dart';
import 'package:telephonist/redis_client.dart';
import 'package:telephonist/stomp_clients.dart';
import 'package:telephonist/args_parser.dart';
import 'package:telephonist/telephonist_util.dart';

main(List<String> args) async {
  Map appConfig = parseArgs(args);
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${config['id']} ${rec.message}');
  });
  final Logger log = new Logger('master');


  for (int workerId = 0; workerId < appConfig['threads']; workerId++) {
    Map workerConfig = new Map.from(appConfig);
    workerConfig['id'] = [appConfig['id'], 'isolate', workerId.toString()].join('_');
     
    Isolate isolate = await Isolate.spawn(worker, workerConfig);
    isolate.errors.listen(log.shout);
  }
}

worker(Map config) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${config['id']} ${rec.message}');
  });

  StompClients stompClients = new StompClients(config['brokers'].map((String raw) => new HostAndPort.fromString(raw)));
  HostAndPort store = new HostAndPort.fromString(config['store']);

  stompClients.connect(login: config['brokers-login'], password: config['brokers-password']).then((StompClients stompClients) {
    RedisClient redisClient = new RedisClient(host: store.host, port: store.port);
    TelephonistServer ts = new TelephonistServer(
      id: config['id'],
      redisClient: redisClient,
      stompClients: stompClients
    )..listen(config['host'], config['port']);
  });
}
