import "package:redis_client/redis_client.dart";

main() {
  var connectionString = "localhost:6379";
  RedisClient.connect(connectionString)
      .then((RedisClient client) {
        // Use your client here. Eg.:
        client.set("test", "value")
            .then((_) => client.get("test"))
            .then((value) => print("success: $value"));
      });
}