import 'dart:html';
import 'package:telephonist/client.dart'; 
import 'dart:convert';

void main() {
  var params = Uri.splitQueryString(window.location.search.substring(1));
  
  var telephonist = new TelephonistClient('ws://${window.location.hostname}:3000/', room: params['roomId']);
  bool enableVideo = params['enableVideo'] == 'true';
  bool enableAudio = params['enableAudio'] == 'true';
  bool enableData = params['enableData'] == 'true';

  telephonist.createStream(video: enableVideo, audio: enableAudio, data: enableData).then((stream) {
    var video = new VideoElement()
      ..autoplay = true
      ..volume = 0
      ..src = Url.createObjectUrl(stream);

    querySelector("#opponents").append(video);
  });

  telephonist.onAdd.listen((message) {
    var video = new VideoElement()
      ..id = 'remote${message['id'].replaceAll(':', '_')}'
      ..autoplay = true
      ..src = Url.createObjectUrl(message['stream']);

    querySelector("#opponents").append(video);
  });

  telephonist.onLeave.listen((message) {
    querySelector('#remote${message['id'].replaceAll(':', '_')}')?.remove();
  });
  
  telephonist.onData.listen((message) {
    querySelector("#messages")..appendText(message['data'])..appendHtml('<br>');
  });
  
  
  querySelector("#messageForm").onSubmit.listen((e) {
    e.preventDefault();
    String message = (querySelector("#message") as InputElement).value;
    querySelector("#messages")..appendText(message)..appendHtml('<br><hr>');
    (querySelector("#messages").lastChild as Element).scrollIntoView();
    telephonist.send(message);
    (querySelector("#message") as InputElement).value = '';
  });
}