import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.id)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching conversations"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.\nHit "Connect" on a post to start chatting!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Figure out who the OTHER person is
              List<dynamic> participantNames = data['participantNames'] ?? [];
              String targetName = participantNames.firstWhere(
                (name) => name != user.fullName, 
                orElse: () => 'A Skill Shift User'
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blueAccent,
                  child: Text(targetName.isNotEmpty ? targetName[0].toUpperCase() : '?'),
                ),
                title: Text(targetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  data['lastMessage'] ?? 'No messages yet', 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: docs[index].id,
                        targetUserName: targetName,
                      ),
                    )
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }
}