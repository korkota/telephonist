import 'package:telephonist/server.dart'; 

void main() {
  TelephonistServer ts = new TelephonistServer()..listen('127.0.0.1', 3000);
}