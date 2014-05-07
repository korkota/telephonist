import 'dart:html';
import 'package:telephonist/client.dart'; 

void main() {
  var speaker = new SpeakerClient('ws://127.0.0.1:3000', room: 'room', user: '123');

  speaker.createStream(video: true).then((stream) {
    var video = new VideoElement()
      ..autoplay = true
      ..src = Url.createObjectUrl(stream);

    document.body.append(video);
  });

  speaker.onAdd.listen((message) {
    var video = new VideoElement()
      ..id = 'remote${message['id']}'
      ..autoplay = true
      ..src = Url.createObjectUrl(message['stream']);

    document.body.append(video);
  });

  speaker.onLeave.listen((message) {
    document.query('#remote${message['id']}').remove();
  });
}