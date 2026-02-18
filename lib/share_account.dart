import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:safe_share/chat.dart'; // Keep your existing chat import

// Premium Styles
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class ShareAccount extends StatefulWidget {
  const ShareAccount({super.key});

  @override
  State<ShareAccount> createState() => _ShareAccountState();
}

class _ShareAccountState extends State<ShareAccount> {
  List<dynamic> Djangodata = [];
  bool isLoading = true;
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    viewUsers();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('DISCOVER', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.2)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : Djangodata.isEmpty
            ? const Center(child: Text("No users found"))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          itemCount: Djangodata.length,
          itemBuilder: (context, index) {
            final item = Djangodata[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          backgroundImage: NetworkImage(imgurl + item['photo']),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                              Text(item['email'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              Text("${item['gender']} • ${item['phone']}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              SharedPreferences sh = await SharedPreferences.getInstance();
                              sh.setString("rid", item['id'].toString());
                              sh.setString("cname", item['name'].toString());
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentChat()));
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text("Chat"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              SharedPreferences sh = await SharedPreferences.getInstance();
                              sh.setString("rid", item['id'].toString());
                              sh.setString("cname", item['name'].toString());
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SharedPostsPage(friendName: item['name'])));
                            },
                            icon: const Icon(Icons. collections_outlined, size: 18, color: Colors.white),
                            label: const Text("Shared", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),

                        ),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              SharedPreferences sh = await SharedPreferences.getInstance();
                              sh.setString("rid", item['id'].toString());
                              sh.setString("cname", item['name'].toString());
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SharedPostsPage(friendName: item['name'])));
                            },
                            icon: const Icon(Icons. share, size: 18, color: Colors.white),
                            label: const Text("Share account", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),

                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class SharedPostsPage extends StatefulWidget {
  final String friendName;
  const SharedPostsPage({super.key, required this.friendName});

  @override
  State<SharedPostsPage> createState() => _SharedPostsPageState();
}

class _SharedPostsPageState extends State<SharedPostsPage> {
  List<dynamic> sharedData = [];
  bool isLoading = true;
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    fetchShared();
  }

  Future<void> fetchShared() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    imgurl = pref.getString('imgurl').toString() + "";
    String? lid = pref.getString('lid');
    String? fid = pref.getString('rid');

    try {
      var response = await http.post(
        Uri.parse("${url!}ViewSharedPost/"),
        body: {'fid': fid!, 'lid': lid!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            sharedData = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shared by ${widget.friendName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 0.5,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : sharedData.isEmpty
            ? const Center(child: Text("No posts shared here yet"))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sharedData.length,
          itemBuilder: (context, index) {
            final post = sharedData[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chat bubble style container
                Container(
                  margin: const EdgeInsets.only(bottom: 20, right: 40), // Pushed to the left like a friend's message
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(imgurl + post['post'], fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post['caption'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(post['description'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Text("Original Owner: ${post['post_owner']}",
                                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: kPrimaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}