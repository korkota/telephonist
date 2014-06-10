library redis_client;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class RedisClient {
  String host;
  int port;
  
  RedisClient({this.host, this.port});
  
  Future<Object> _callAPI(String command, List<String> params) {
    Completer completer = new Completer();
    String encodingParams = JSON.encode(params);
    Map<String, String> queryParameters = {"params": encodingParams};
    
    Uri uri = new Uri(
        scheme: 'http', 
        host: host, 
        port: port, 
        path: 'api/' + command,
        queryParameters: queryParameters);
    
    new HttpClient().getUrl(uri)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) => response.transform(UTF8.decoder).transform(JSON.decoder).first)
      .then((response) { 
        if (response is List<String>) {
          completer.complete((response as List<String>).toSet());
        } else {
          completer.complete(response);
        }
      })
      .catchError((error) => print(error));
    
    return completer.future;
  }
  
  Future<String> get(String key) => _callAPI('get', [key]);
  
  Future<String> set(String key, String value) => _callAPI('set', [key, value]);
  
  Future<String> sadd(String key, String value) => _callAPI('sadd', [key, value]);

  Future<Set<String>> smembers(String key) => _callAPI('smembers', [key]);
  
  Future<String> srem(String key, String value) => _callAPI('srem', [key, value]);
  
  Future<String> del(String key) => _callAPI('del', [key]);
}