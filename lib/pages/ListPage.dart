// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:videocall_webrtc/pages/VideoCallPage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Listpage extends StatefulWidget {
  const Listpage({super.key});
  @override
  State<Listpage> createState() => _ListpageState();
}

class _ListpageState extends State<Listpage> {
  List<dynamic> availableClients = [];
  List<dynamic> statusClients = [];
  late WebSocketChannel channel;
  late Stream broadcastStream;
  StreamSubscription<dynamic>? subscription;
  int? userId;

  Future<void> setUpBroadCastStream() async {
    channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/socket"));
    broadcastStream = channel.stream.asBroadcastStream();
  }

  void setUpOnMessage() {
    subscription = broadcastStream.listen((message) {
      Map<String, dynamic> mp = jsonDecode(message);
      switch (mp["messageType"]) {
        case "INITIAL":
          setState(() {
            userId = mp["userId"];
            List<dynamic> x = mp["clientList"];
            List<dynamic> y = mp["clientStatusList"];
            availableClients = x;
            statusClients = y;
            int idx = availableClients.indexOf(userId);
            availableClients.removeAt(idx);
            statusClients.removeAt(idx);
          });
          break;
        case "BROADCAST":
          setState(() {
            List<dynamic> x = mp["clientList"];
            List<dynamic> y = mp["clientStatusList"];
            availableClients = x;
            statusClients = y;
            int idx = availableClients.indexOf(userId);
            availableClients.removeAt(idx);
            statusClients.removeAt(idx);
          });
          break;
      }
    });
  }

  Future<void> setUpWebSocketConnection() async {
    await setUpBroadCastStream();
    setUpOnMessage();
  }

  @override
  void initState() {
    setUpWebSocketConnection();
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
        backgroundColor: Theme.of(context).primaryColorDark,
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
                // final status = statusClients[index];
                final status = true;
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        Icons.person,
                      ),
                    ),
                    title: Text(
                      "$client",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    trailing: ElevatedButton(
                      // onPressed: null,
                      onPressed: (status)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoCallPage(
                                    listPageSubscription: subscription!,
                                    broadcastStream: broadcastStream,
                                    channel: channel,
                                    isCalling: true,
                                    myId: userId!,
                                    toId: client,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.call), // Blocked icon
                        SizedBox(width: 8),
                        Text('Connect'),
                      ]),
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
              //set up room and wait for offer sdp
              builder: (context) => VideoCallPage(
                listPageSubscription: subscription!,
                broadcastStream: broadcastStream,
                channel: channel,
                isCalling: false,
                myId: userId!,
                toId: -99,
              ),
            ),
          );
        },
        child: Icon(Icons.video_call),
      ),
    );
  }
}
