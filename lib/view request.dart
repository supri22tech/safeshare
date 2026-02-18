import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class viewRequest extends StatefulWidget {
  const viewRequest({super.key});

  @override
  State<viewRequest> createState() => _viewRequestState();
}

class _viewRequestState extends State<viewRequest> {
  List<dynamic> Djangodata = [];
  bool isLoading = true;
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    viewUsers();
  }

  // Fetch Friend Requests
  Future<void> viewUsers() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    imgurl = pref.getString('imgurl').toString();
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}view_request/"),
        body: {'lid': lid!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            Djangodata = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Handle Accept/Reject
  Future<void> handleRequest(String requestId, String action) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');

    // Choose endpoint based on action
    String endpoint = action == "accept" ? "accept_request/" : "reject_request/";

    try {
      var response = await http.post(
        Uri.parse("$url$endpoint"),
        body: {
          'id': requestId, // This is usually the Request ID or Other User ID
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request ${action == 'accept' ? 'Accepted' : 'Rejected'}")),
        );
        viewUsers(); // Refresh the list
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF0097A7); // Cyan 700

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('FRIEND REQUESTS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Djangodata.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: Djangodata.length,
        itemBuilder: (context, index) {
          final item = Djangodata[index];
          return _buildRequestCard(item, kPrimaryColor);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic item, Color themeColor) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Avatar with Border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(imgurl + item['photo']),
                  ),
                ),
                const SizedBox(width: 15),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['user'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      _infoRow(Icons.email_outlined, item['email']),
                      _infoRow(Icons.phone_android_outlined, item['phone']),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => handleRequest(item['id'].toString(), "accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("ACCEPT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => handleRequest(item['id'].toString(), "reject"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_disabled_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No pending requests", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}