import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';


void main(){
  final channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/socket"));
  channel.stream.listen((event) {
    print("hey");
    List<dynamic> x = jsonDecode(event);
  },);
  // channel.sink.close();
}