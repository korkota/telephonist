library telephonist_util;

import 'dart:io';

class HostAndPort {
  String _host;
  int _port;
  
  HostAndPort(this._host, this._port);
  
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
  
  SocketId.fromServerIdAndSocket(this._serverId, WebSocket socket) {
    _socketId = _serverId + SEPARATOR + socket.hashCode.toString();
  }
  
  String get serverId => _serverId;
  
  String toString() => _socketId;
}