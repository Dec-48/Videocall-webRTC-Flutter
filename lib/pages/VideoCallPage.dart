// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoCallPage extends StatefulWidget {
  final Stream broadcastStream;
  final WebSocketChannel channel;
  final bool isCalling;
  final int myId;
  final int toId;
  const VideoCallPage({
    super.key,
    required this.channel,
    required this.broadcastStream,
    required this.isCalling,
    required this.myId,
    required this.toId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool onLoading = true;
  bool isHangup = false;
  RTCVideoRenderer? _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer? _remoteRenderer = RTCVideoRenderer();
  StreamSubscription<dynamic>? subscription;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  void setUpOnMessage(Stream broadcastStream, WebSocketChannel channel) {
    subscription = broadcastStream.listen((message) async {
      Map<String, dynamic> mp = jsonDecode(message);
      switch (mp["type"]) {
        case "offer": //recieve offer/sdp from other user
          _peerConnection!.onIceCandidate = (RTCIceCandidate iceCandidate) {
            channel.sink.add(jsonEncode({
              "type": "ice",
              "myId": mp["toId"],
              "candidate": iceCandidate.candidate,
              "sdpMid": iceCandidate.sdpMid,
              "sdpMLineIndex": iceCandidate.sdpMLineIndex,
              "toId": mp["myId"],
            }));
          };
          await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(mp["sdp"], mp["type"]));
          RTCSessionDescription answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          channel.sink.add(jsonEncode({
            "type": "answer",
            "myId": mp["toId"],
            "sdp": answer.sdp,
            "toId": mp["myId"]
          }));
          break;

        case "answer":
          print(mp["type"]);
          RTCSessionDescription answer =
              RTCSessionDescription(mp["sdp"], mp["type"]);
          try {
            await _peerConnection!.setRemoteDescription(answer);
          } catch (e) {
            print(e.toString());
          }
          break;

        case "ice":
          RTCIceCandidate iceCandidate = RTCIceCandidate(
              mp["candidate"], mp["sdpMid"], mp["sdpMLineIndex"]);
          _peerConnection!.addCandidate(iceCandidate);
          break;

        default:
          // do nothing.
          // type BOARDCAST (other user might connect/disconnect to websocket)
          break;
      }
    });
  }

  void unsubscription() async {
    if (subscription != null) {
      await subscription!.cancel();
      subscription = null;
    }
  }

  Future<void> createOfferToId(int toId, WebSocketChannel channel) async {
    RTCSessionDescription offer =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    _peerConnection!.setLocalDescription(offer);
    //Send to toId
    channel.sink.add(jsonEncode({
      "type": offer.type,
      "myId": widget.myId,
      "sdp": offer.sdp,
      "toId": toId
    }));
  }

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
    _peerConnection = await createPeerConnection(configuration);
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer!.initialize();
    await _remoteRenderer!.initialize();
    setState(() {});
  }

  Future<void> setupRenderer() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": {"facingMode": "user"}
    });
    _localRenderer!.srcObject = _localStream;

    _localRenderer!.srcObject!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localRenderer!.srcObject!);
    });

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      _remoteRenderer!.srcObject = event.streams[0];
    };

    _peerConnection!.onConnectionState = (e) {
      // print(e);
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      _remoteRenderer!.srcObject = stream;
      // setState(() {}); //? no need ?
    };
  }

  Future<void> setupRoom() async {
    await registerPeerConnection();
    await _initializeRenderers();
    await setupRenderer();
    if (widget.isCalling) {
      createOfferToId(widget.toId, widget.channel);
    }
    setUpOnMessage(widget.broadcastStream, widget.channel);
  }

  Future<void> _dispose() async {
    //stop every track in local and remote
    Future<void> stop() async {
      try {
        _localRenderer!.srcObject!.getTracks().forEach((track) => track.stop());
        _remoteRenderer!.srcObject!
            .getTracks()
            .forEach((track) => track.stop());
      } catch (e) {
        print(e.toString());
      }
    }

    await stop();
    if (_localRenderer != null) {
      await _localRenderer?.dispose();
    }
    if (_remoteRenderer != null) {
      await _remoteRenderer?.dispose();
    }
    if (_peerConnection != null) {
      await _peerConnection?.close();
    }
    if (_localStream != null) {
      await _localStream?.dispose();
    }
    _localRenderer = null;
    _remoteRenderer = null;
    _peerConnection = null;
    _localStream = null;
  }

  @override
  void initState() {
    setupRoom();
    super.initState();
  }

  @override
  void dispose() {
    unsubscription();
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calling Page"),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video Feed (Main View)
          Positioned.fill(
            child: Container(
              child: RTCVideoView(
                _remoteRenderer!,
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
                  _localRenderer!,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Mute Logic
                          },
                          icon: Icon(Icons.mic, color: Colors.white),
                          tooltip: 'Mute/Unmute',
                        ),
                        IconButton(
                          onPressed: () {
                            // hangUp();
                            // setState(() {
                            //   isHangup = true;
                            // });
                            Navigator.pop(context);
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
                  'Calling Page',
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
