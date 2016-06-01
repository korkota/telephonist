library args_parser;

import 'dart:io';

import 'package:args/args.dart';

Map parseArgs(List<String> args) {
  ArgParser parser = new ArgParser();

  parser.addOption('brokers',
    abbr: 'b',
    help: "List of brokers' hosts and ports.",
    defaultsTo: '127.0.0.1:61613'
  );

  parser.addOption('brokers-login',
    help: 'Login for brokers.',
    defaultsTo: 'admin'
  );

  parser.addOption('brokers-password',
    help: 'Password for brokers.',
    defaultsTo: 'password'
  );

  parser.addOption('id',
    abbr: 'i',
    help: 'Server ID.',
    defaultsTo: 'alpha'
  );

  parser.addOption('host',
    abbr: 'h',
    help: 'Host name.',
    defaultsTo: '0.0.0.0'
  );

  parser.addOption('port',
    abbr: 'p',
    help: 'Port number.',
    defaultsTo: '3000'
  );

  parser.addOption('store',
    abbr: 's',
    help: 'Distributed data store.',
    defaultsTo: '127.0.0.1:12000'
  );

  parser.addOption('threads',
    abbr: 't',
    help: 'Number of threads.',
    defaultsTo: Platform.numberOfProcessors.toString()
  );

  parser.addFlag(
    'help',
    help: 'Prints this help.',
    negatable: false,
    callback: (printHelp) {
      if (printHelp) {
        print('Distributed server for WebRTC signaling.\n');
        print(parser.usage);
        exit(0);
      }
    }
  );

  ArgResults results = parser.parse(args);

  return {
    'brokers': results['brokers'].split(','),
    'brokers-login': results['brokers-login'],
    'brokers-password': results['brokers-password'],
    'id': results['id'],
    'host': results['host'],
    'port': int.parse(results['port'], onError: (_) => 4040),
    'store': results['store'],
    'threads': int.parse(results['threads'], onError: (_) => Platform.numberOfProcessors)
  };
}