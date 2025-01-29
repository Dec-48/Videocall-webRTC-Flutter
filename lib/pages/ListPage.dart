// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:videocall_webrtc/pages/VideoCallPage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
class Listpage extends StatefulWidget {
  const Listpage({super.key});
  @override
  State<Listpage> createState() => _ListpageState();
}

class _ListpageState extends State<Listpage> {
  List<dynamic> availableClients = [];
  late WebSocketChannel channel;
  late Stream broadcastStream;
  bool onLoading = true;
  int? myId;

  Future<void> setupBroadcasts() async {
    channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/socket"));
    broadcastStream = channel.stream.asBroadcastStream();
  }

  void setOnmessage(){
    broadcastStream.listen((message) {
      Map<String, dynamic> mp = jsonDecode(message);  
      switch (mp["type"]){
        case "initial" :
          setState(() {
            myId = mp["myId"];
            List<dynamic> x = jsonDecode(mp["list"]);
            availableClients = x;
            availableClients.remove(myId);
          });
          print("i am : $myId");
          break;
        case "fetchList":
          setState(() {
                  List<dynamic> x = jsonDecode(mp["list"]);
                  availableClients = x;
                  availableClients.remove(myId);
                });
          break;
      }
    });
  }

  @override
  void initState() {
    setupBroadcasts();
    setOnmessage();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Clients'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Clients for Connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableClients.length,
              itemBuilder: (context, index) {
                final client = availableClients[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:Colors.green,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      "$client",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallPage(
                              broadcastStream: broadcastStream,
                              channel: channel,
                              isCalling: true,
                              myId: myId!,
                              toId: client,
                            ),
                          ),
                        );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text('Connect'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallPage(
                broadcastStream: broadcastStream,
                channel: channel,
                isCalling: false,
                myId: myId!,
                toId: -99,
              ),
            ),
          );
        },
        child: Icon(Icons.room_preferences_sharp),
      ),
    );
  }
}