library stomp_clients;

import "dart:io";
import "dart:async";

import "package:telephonist/telephonist_util.dart";
import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" as Stomp;

class StompClients {
  List<StompClient> _clients;
  List<HostAndPort> _addresses;
  
  StompClients(this._addresses);
  
  Future<StompClients> connect() {
    Completer completer = new Completer();
    
    Future.wait(_addresses.map((HostAndPort address) => Stomp.connect(address.host, port: address.port)))
    .then((List<StompClient> clients) {
      _clients = clients;
      completer.complete(this);
    });
    
    return completer.future;
  }
  
  void subscribeJson(String destination, void onMessage(Map<String, String> headers, message)) {
    _clients.forEach((StompClient client) => client.subscribeJson('0', destination, onMessage));
  }
  
  void sendJson(String destination, message) {
    _clients
    .firstWhere((StompClient client) => !client.isDisconnected)
    .sendJson(destination, message);
  }
}