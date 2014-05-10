import 'dart:html';
import 'package:telephonist/client.dart'; 

void main() {
  var speaker = new TelephonistClient('ws://127.0.0.1:3000', room: '1111');
  
  speaker.createStream(video: true).then((stream) {
    var video = new VideoElement()
      ..autoplay = true
      ..src = Url.createObjectUrl(stream);

    document.body.append(video);
  });

  speaker.onAdd.listen((message) {
    var video = new VideoElement()
      ..id = 'remote${message['id'].replaceAll(':', '_')}'
      ..autoplay = true
      ..src = Url.createObjectUrl(message['stream']);

    document.body.append(video);
  });

  speaker.onLeave.listen((message) {
    document.query('#remote${message['id'].replaceAll(':', '_')}').remove();
  });
}