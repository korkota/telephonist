import 'dart:html';
import 'package:telephonist/client.dart'; 
import 'dart:convert';

void main() {
  var params = Uri.splitQueryString(window.location.search.substring(1));
  
  var telephonist = new TelephonistClient('ws://127.0.0.1:3000', room: params['roomId']);
  
  telephonist.createStream(video: true, audio: true).then((stream) {
    var video = new VideoElement()
      ..autoplay = true
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
    document.query('#remote${message['id'].replaceAll(':', '_')}').remove();
  });
  
  telephonist.onData.listen((message) {
    querySelector("#messages")..appendText(message['data'])..appendHtml('<br>');
  });
  
  
  querySelector("#sendButton").onClick.listen((e) {
    String message = (querySelector("#message") as InputElement).value;
    querySelector("#messages")..appendText(message)..appendHtml('<br>');;
    telephonist.send(message);
  });
}