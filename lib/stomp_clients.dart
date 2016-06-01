library stomp_clients;

import "dart:io";
import "dart:async";
import "dart:convert";

import 'package:logging/logging.dart';

import "package:telephonist/telephonist_util.dart";
import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" as Stomp;

class StompClients {
  List<StompClient> _clients;
  List<HostAndPort> _addresses;

  final Logger _log = new Logger('broker');
  
  StompClients(this._addresses);
  
  Future<StompClients> connect({login: 'admin', password: 'password'}) {
    Completer completer = new Completer();
    
    Future.wait(_addresses.map((HostAndPort address) => Stomp.connect(address.host, port: address.port, login: login, passcode: password)))
    .then((List<StompClient> clients) {
      _clients = clients;
      completer.complete(this);
    });
    
    return completer.future;
  }
  
  void subscribeJson(String id, String destination, void onMessage(Map<String, String> headers, message)) {
    _clients.forEach((StompClient client) => client.subscribeJson(id, '/queue' + destination, onMessage));
  }
  
  void sendJson(String destination, message) {
    _log.info('has sent the message to ${destination.substring(1)} via brocker:\n${prettyJson(JSON.decode(message['data']))}');

    _clients
    .firstWhere((StompClient client) => !client.isDisconnected)
    .sendJson('/queue' + destination, message);
  }
}