import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" show connect;

void main() {
  connect("127.0.0.1", port: 10000).then((StompClient client) {
    client.subscribeString("0", "/foo",
      (Map<String, String> headers, String message) {
        print("Recieve $message");
      });

    client.sendString("/foo", "Hi, Stomp");
  });
}