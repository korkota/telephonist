import 'dart:html';

void main() {
  querySelector("#signInForm").onSubmit.listen((e) {
    e.preventDefault();
    String roomId = (querySelector("#roomId") as InputElement).value;
    bool enableAudio = (querySelector("#enableAudio") as CheckboxInputElement).checked;
    bool enableVideo = (querySelector("#enableVideo") as InputElement).checked;
    bool enableData = (querySelector("#enableData") as InputElement).checked;
    window.location.assign(
        'clientwebrtc.html?roomId=$roomId&enableAudio=$enableAudio&enableVideo=$enableVideo&enableData=$enableData');
  });
}
