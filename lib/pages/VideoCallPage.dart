import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoCallPage extends StatefulWidget {
  // final String clientName; // Property of the StatefulWidget
  final int clientId;
  final WebSocketChannel channel;
  final int toId;

  const VideoCallPage({Key? key, required this.clientId, required this.toId, required this.channel}) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool onLoading = true;
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel channel;
  int? senderId;
  int? toId;

  Future<void> registerPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };
    // MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints)
    _localRenderer.srcObject = await navigator.mediaDevices.getUserMedia({
      "audio" : true,
      "video" : {
        "facingMode" : "user"
      }
    });
    _peerConnection = await createPeerConnection(configuration);

    _localRenderer.srcObject!.getTracks().forEach((track){
      _peerConnection!.addTrack(track, _localRenderer.srcObject!);
    });
    
    _peerConnection!.onTrack = (RTCTrackEvent event){
      _remoteRenderer.srcObject = event.streams[0];
    };

    _peerConnection!.onConnectionState = (e) {
      print(e);
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    };
  }

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
          });
          print("i am : $senderId");
          break;

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
          RTCIceCandidate iceCandidate = RTCIceCandidate(
            mp["candidate"],
            mp["sdpMid"],
            mp["sdpMLineIndex"]
          );
          _peerConnection?.addCandidate(iceCandidate);
          break;

        default:
          print("invalid : ");
          print(mp);
      }
    },);
  }

  Future<void> createOfferToId() async {
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
    await registerPeerConnection();
    await setupWebsocket();
    setState(() {
      onLoading = false; //TODO : loading success
    });
  }


  @override
  void initState() {
    _initializeRenderers();
    registerPeerConnection();
    // setupRoom();
    print('Connecting to client: ${widget.clientId}'); // Access widget.clientName here
    super.initState();
  }

  Future<void> _initializeRenderers() async { //! refactor please
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video Feed (Main View)
          Positioned.fill(
            child: Container(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),

          // Local Video Feed (Floating Preview)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    //TODO color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),

          // Control Buttons (Floating Bar)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  //TODO color: Colors.grey.shade900.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      //TODO color: Colors.black.withOpacity(0.6),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(controller: _controller,),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              toId = int.parse(_controller.text);
                            });
                            print(toId);
                            await createOfferToId();
                          },
                          child: Text("call from : $senderId"),
                        ),
                        IconButton(
                          onPressed: () {
                            // Mute Logic
                          },
                          icon: Icon(Icons.mic, color: Colors.white),
                          tooltip: 'Mute/Unmute',
                        ),
                        IconButton(
                          onPressed: () {
                            // End Call Logic
                          },
                          icon: Icon(Icons.call_end, color: Colors.red),
                          tooltip: 'End Call',
                        ),
                        IconButton(
                          onPressed: () {
                            // Camera Switch Logic
                          },
                          icon: Icon(Icons.switch_camera, color: Colors.white),
                          tooltip: 'Switch Camera',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // AppBar with Title
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  'Connected with ${widget.clientId}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
