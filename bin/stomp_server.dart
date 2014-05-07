import 'package:ripple/ripple.dart';
import 'dart:async';

final int port = 10000; 

void main() {
  RippleServer server = new RippleServer();
  Future<RippleChannel> afterStart = server.start(port: port);
  afterStart.then((_) => print('Server started on port ${port}.'));
}
