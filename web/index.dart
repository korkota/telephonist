import 'dart:html';

void main() {
  querySelector("#joinButton").onClick.listen((e) {
    String roomId = (querySelector("#roomId") as InputElement).value;
    window.location.assign('clientwebrtc.html?roomId=$roomId');
  });
}