import 'package:flutter/material.dart';
import 'package:videocall_webrtc/pages/CallPage.dart';

class Homepage extends StatelessWidget {
  Homepage({super.key});
  final List<Map<String, String>> availableClients = [
    {'name': 'Client 1', 'status': 'Online'},
    {'name': 'Client 2', 'status': 'Online'},
    {'name': 'Client 3', 'status': 'Offline'},
    {'name': 'Client 4', 'status': 'Online'},
  ];

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
                      backgroundColor: client['status'] == 'Online'
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      client['name']!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(client['status']!),
                    trailing: ElevatedButton(
                      onPressed: client['status'] == 'Online'
                          ? () {
                              // Navigate to Video Call Page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoCallPage(
                                    clientName: client['name']!,
                                  ),
                                ),
                              );
                            }
                          : null,
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