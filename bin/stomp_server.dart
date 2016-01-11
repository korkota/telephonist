import 'package:ripple/ripple.dart';
import 'package:logging/logging.dart';
import 'dart:async';

final int port = 10000; 

void main() {
  hierarchicalLoggingEnabled = true;
  RippleServer server = new RippleServer()..logger.level = Level.FINEST;
  Future<RippleChannel> afterStart = server.start(port: port);
  afterStart.then((RippleChannel channel) {
    print('Server started on port ${port}.');
  });
}
