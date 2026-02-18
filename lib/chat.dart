import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Reuse the premium styles from your other pages
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class StudentChat extends StatefulWidget {
  const StudentChat({super.key});

  @override
  State<StudentChat> createState() => _StudentChatState();
}

class _StudentChatState extends State<StudentChat> {
  final TextEditingController msgCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  List messages = [];
  String? url;
  String? lid;
  String? staffAuthId;
  String? staffName;
  bool loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when leaving the chat
    msgCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final pref = await SharedPreferences.getInstance();
    url = pref.getString('url');
    lid = pref.getString('lid');
    staffAuthId = pref.getString('rid');
    staffName = pref.getString('cname');

    loadChat();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      loadChat();
    });
  }

  Future<void> loadChat() async {
    if (url == null || lid == null || staffAuthId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final res = await http.post(Uri.parse('$url/flut_view_chat/'), body: {
        'fromid': lid!,
        'toid': staffAuthId!,
        'sender_type': 'student',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'ok') {
          setState(() {
            messages = data['data'] ?? [];
            loading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollCtrl.hasClients) {
              scrollCtrl.animateTo(
                scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> sendMessage() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;
    if (url == null || lid == null || staffAuthId == null) return;

    try {
      final res = await http.post(Uri.parse('$url/flut_send_chat/'), body: {
        'fromid': lid!,
        'toid': staffAuthId!,
        'message': text,
        'sender_type': 'student',
      });

      if (res.statusCode == 200) {
        msgCtrl.clear();
        await loadChat();
      }
    } catch (e) {
      // Handle exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              child: Text(staffName?[0].toUpperCase() ?? "S",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(staffName ?? "Staff",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : messages.isEmpty
                  ? _buildEmptyChat()
                  : ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['fromid'].toString() == lid;
                  return _buildChatBubble(msg['message'], isMe);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: kPrimaryColor.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text("No messages yet", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: msgCtrl,
                decoration: InputDecoration(
                  hintText: 'Write your message...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}