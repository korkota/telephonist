library telephonist_util;

import 'dart:convert';

class HostAndPort {
  String _host;
  int _port;
  
  HostAndPort(this._host, this._port);

  HostAndPort.fromString(String raw) {
    List<String> hostAndPort = raw.split(':');
    this._host = hostAndPort[0];
    this._port = int.parse(hostAndPort[1]);
  }

  String get host => _host;
  int get port => _port;
}

class SocketId {
  static final String SEPARATOR = ':';
  
  String _socketId;
  String _serverId;
  
  SocketId(this._socketId) {
    _serverId = _socketId.split(SEPARATOR).first;
  }
  
  String get serverId => _serverId;
  
  String toString() => _socketId;
}

JsonEncoder encoder = new JsonEncoder.withIndent('  ');
Function prettyJson = (json) => encoder.convert(json);

Function buildGlobalId = (serverId, connectionId) => '$serverId:$connectionId';