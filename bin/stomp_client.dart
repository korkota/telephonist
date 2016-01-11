import "package:stomp/stomp.dart";
import "package:stomp/vm.dart" show connect;

void main() {
  connect("127.0.0.1", port: 61613, login: 'admin', passcode: 'password').then((StompClient client) {
    client.subscribeJson("test", "/queue/test",
      (Map<String, String> headers, Object message) {
        print("0 Recieve $message");
      });

    client.sendJson("/queue/test", {"test":"test"});

  });


}