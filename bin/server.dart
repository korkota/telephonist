import 'package:telephonist/server.dart';
import 'packagee:redis_client/redis_client.dart';

void main() {
  var connectionString = "localhost:6379";
  
  RedisClient.connect(connectionString)
    .then((RedisClient client) {
      TelephonistServer ts = new TelephonistServer('testId', client)..listen('127.0.0.1', 3000);
      // Use your client here. Eg.:
      client.set("test", "value")
          .then((_) => client.get("test"))
          .then((value) => print("success: $value"));
    });
}