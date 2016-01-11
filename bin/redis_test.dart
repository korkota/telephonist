import "package:telephonist/redis_client.dart";

main() {
  RedisClient redisClient = new RedisClient(host: '127.0.0.1', port: 12000);
  
  redisClient.set('dart', 'awesome!')
    .then((_) => redisClient.get('dart'))
    .then((String value) => print(value))
    .then((_) => redisClient.sadd('room:1000', '1:101010'))
    .then((_) => redisClient.smembers('room:1000'))
    .then((Set<String> value) => print(value));

//  var connectionString = "127.0.0.1:6379";
//  RedisClient.connect(connectionString)
//      .then((RedisClient client) {
//        // Use your client here. Eg.:
//        client.set("test", "value")
//            .then((_) => client.get("test"))
//            .then((value) => print("success: $value"));
//      });
}