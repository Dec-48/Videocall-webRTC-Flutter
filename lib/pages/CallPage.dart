import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallPage extends StatefulWidget {
  final String clientName; // Property of the StatefulWidget

  const VideoCallPage({Key? key, required this.clientName}) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    _initializeRenderers();
    print('Connecting to client: ${widget.clientName}'); // Access widget.clientName here
    super.initState();
  }

  Future<void> _initializeRenderers() async {
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
                child: Row(
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
                  'Connected with ${widget.clientName}',
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
