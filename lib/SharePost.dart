

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safe_share/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class viewFriendsShare extends StatefulWidget {
  const viewFriendsShare({super.key});

  @override
  State<viewFriendsShare> createState() => _viewFriendsShareState();
}

class _viewFriendsShareState extends State<viewFriendsShare> {
  List<dynamic> Djangodata = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    viewUsers();
  }
  String  imgurl="";
  // Fetch Users
  Future<void> viewUsers() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    imgurl = pref.getString('imgurl').toString();
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}view_myFriends/"),
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

  // NEW: Send Request Function
  Future<void> sendRequest(String otherUserLid) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    String? pid = pref.getString('pid');

    try {
      var response = await http.post(
        Uri.parse("${url!}share_post/"), // Ensure you create this endpoint in Django
        body: {
          'lid': lid!,
          'to': otherUserLid,
          'post': pid,
        },
      );

      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['status'] == 'ok' ? "Shared !" : "Failed to Share")),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? baseUrl = ""; // You might need your base URL for images

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Discover People', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.cyan.shade700,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Djangodata.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: Djangodata.length,
        itemBuilder: (context, index) {
          final item = Djangodata[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Profile Photo
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.cyan.shade100,
                    backgroundImage: NetworkImage(imgurl+item['photo']), // Ensure 'photo' is a full URL
                  ),
                  const SizedBox(width: 15),

                  // User Details
                  Expanded(
                    child: Column(

                      children: [
                        Row(
                          children: [
                            // Icon(Icons.person, size: 14, color: Colors.cyan.shade700),
                            const SizedBox(width: 5),
                            Text(
                              item['name'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Icon(Icons.email, size: 14, color: Colors.cyan.shade700),
                            const SizedBox(width: 5),
                            Text(item['email'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.cyan.shade700),
                            const SizedBox(width: 5),
                            Text(item['phone'], style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.cyan.shade700),
                            const SizedBox(width: 5),
                            Text(" ${item['gender']}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),

                      ],
                    ),
                  ),

                  // Send Request Button
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences sh=await SharedPreferences.getInstance();
                      sh.setString("rid", item['id'].toString());

                     sendRequest(item['id'].toString());
                    }
                    // => sendRequest(item['id'].toString())
                    ,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Share"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}