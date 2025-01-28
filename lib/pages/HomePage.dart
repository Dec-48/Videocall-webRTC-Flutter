import 'package:flutter/material.dart';
import 'package:videocall_webrtc/pages/VideoCallPage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
class Homepage extends StatefulWidget {
  Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<dynamic> availableClients = [];
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool onLoading = true;
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel channel;
  int? senderId;

  // Future<void> registerPeerConnection() async {
  //     final Map<String, dynamic> configuration = {
  //       'iceServers': [
  //         {
  //           'urls': [
  //             'stun:stun1.l.google.com:19302',
  //             'stun:stun2.l.google.com:19302'
  //           ]
  //         }
  //       ]
  //     };
  //     // MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints)
  //     _localRenderer.srcObject = await navigator.mediaDevices.getUserMedia({
  //       "audio" : true,
  //       "video" : {
  //         "facingMode" : "user"
  //       }
  //     });
  //     _peerConnection = await createPeerConnection(configuration);

  //     _localRenderer.srcObject!.getTracks().forEach((track){
  //       _peerConnection!.addTrack(track, _localRenderer.srcObject!);
  //     });
      
  //     _peerConnection!.onTrack = (RTCTrackEvent event){
  //       _remoteRenderer.srcObject = event.streams[0];
  //     };

  //     _peerConnection!.onConnectionState = (e) {
  //       print(e);
  //     };

  //     _peerConnection!.onAddStream = (MediaStream stream) {
  //       _remoteRenderer.srcObject = stream;
  //       setState(() {});
  //     };
  //   }

    Future<void> setupWebsocket() async {
        channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/socket"));
        // channel.sink.add(jsonEncode({ //TODO : assign random id
        //   "type" : "myId", 
        //   "myId" : widget.clientId
        // }));
        channel.stream.listen((message) async {
          Map<String, dynamic> mp = jsonDecode(message);  
          switch (mp["type"]) {

            case "initial":
              setState(() {
                senderId = mp["senderId"];
                List<dynamic> x = jsonDecode(mp["list"]);
                availableClients = x;
              });
              print("i am : $senderId");
              break;

            case "fetchList":
              setState(() {
                  List<dynamic> x = jsonDecode(mp["list"]);
                  availableClients = x;
                });

            case "offer" :
              _peerConnection!.onIceCandidate = (RTCIceCandidate iceCandidate){ //TODO:
                channel.sink.add(jsonEncode({
                  "type" : "ice",
                  "senderId" : mp["toId"],
                  "candidate" : iceCandidate.candidate,
                  "sdpMid" : iceCandidate.sdpMid,
                  "sdpMLineIndex" : iceCandidate.sdpMLineIndex,
                  "toId" : mp["senderId"],
                }));
              }; 
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(
                  mp["sdp"],
                  mp["type"]
                )
              );
              RTCSessionDescription answer = await _peerConnection!.createAnswer();
              await _peerConnection!.setLocalDescription(answer);
              channel.sink.add(jsonEncode({
                "type" : "answer",
                "senderId" : mp["toId"],
                "sdp" : answer.sdp,
                "toId" : mp["senderId"]
              }));
              break;

            case "answer" :
              RTCSessionDescription answer = RTCSessionDescription(
                mp["sdp"],
                mp["type"]
              );
              await _peerConnection!.setRemoteDescription(answer);
              break;

            case "ice" :
              print("i am $senderId : calling ice");
              RTCIceCandidate iceCandidate = RTCIceCandidate(
                mp["candidate"],
                mp["sdpMid"],
                mp["sdpMLineIndex"]
              );
              _peerConnection!.addCandidate(iceCandidate);
              break;

            default:
              print("weird : : ");
              print("weird : : ");
              print(mp);
          }
        },);
      }
  
  Future<void> createOfferToId(int toId) async {
    _peerConnection!.onIceCandidate = (RTCIceCandidate iceCandidate){ //TODO:
            channel.sink.add(jsonEncode({
              "type" : "ice",
              "senderId" : senderId,
              "candidate" : iceCandidate.candidate,
              "sdpMid" : iceCandidate.sdpMid,
              "sdpMLineIndex" : iceCandidate.sdpMLineIndex,
              "toId" : toId,
            }));
          }; 
    RTCSessionDescription offer = await _peerConnection!.createOffer(
        {'offerToReceiveVideo': 1}
      );
      _peerConnection!.setLocalDescription(offer);
      channel.sink.add(jsonEncode({
            "type" : offer.type,
            "senderId" : senderId,
            "sdp" : offer.sdp,
            "toId" : toId
      }));
  }


  Future<void> setupRoom() async {
    // await registerPeerConnection();
    await setupWebsocket();
    setState(() {
      onLoading = false; //TODO : loading success
    });
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    setState(() {});
  }

  @override
  void initState() {
    // _initializeRenderers();
    setupRoom();
    super.initState();
  }

  @override
  void dispose() {
    // _localRenderer.dispose();
    // _remoteRenderer.dispose();
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
          // Header
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
          // Client List
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
                              // Navigate to Video Call Page
                              createOfferToId(client);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoCallPage(
                                    clientId: senderId!, //TODO : gene random
                                    toId: client,
                                    channel: channel,
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
    );
  }
}