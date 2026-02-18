import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:safe_share/chat.dart'; // Ensure this path is correct in your project

// Premium Styles
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class viewFriends extends StatefulWidget {
  const viewFriends({super.key});

  @override
  State<viewFriends> createState() => _viewFriendsState();
}

class _viewFriendsState extends State<viewFriends> {
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

  // Function to trigger the share bottom sheet
  void _openShareBottomSheet(String accountIdToShare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheetprofile(accId: accountIdToShare),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('DISCOVER',
            style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.2)),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              SharedPreferences sh = await SharedPreferences.getInstance();
                              sh.setString("rid", item['id'].toString());
                              sh.setString("cname", item['name'].toString());
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SharedPostsPage(friendName: item['name'])));
                            },
                            icon: const Icon(Icons.collections_outlined, size: 18, color: Colors.white),
                            label: const Text("Posts", style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // 1. Save the account ID to SharedPreferences
                              final pref = await SharedPreferences.getInstance();
                              await pref.setString("accid", item['id'].toString());

                              // 2. Open the bottom sheet
                              _openShareBottomSheet(item['id'].toString());
                            },
                            icon: const Icon(Icons.share, size: 18, color: Colors.white),
                            label: const Text("Share", style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade700,
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

// --- SHARE BOTTOM SHEET WIDGET ---
class ShareBottomSheetprofile extends StatefulWidget {
  final String accId; // The ID of the account being shared

  const ShareBottomSheetprofile({super.key, required this.accId});

  @override
  State<ShareBottomSheetprofile> createState() => _ShareBottomSheetprofileState();
}

class _ShareBottomSheetprofileState extends State<ShareBottomSheetprofile> {
  List<dynamic> friendsList = [];
  bool isLoading = true;
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    imgurl = pref.getString('imgurl').toString();
    String? lid = pref.getString('lid');
    String? accid = pref.getString('accid');
    print(accid);
    print("*****************************************");

    try {
      var response = await http.post(
        Uri.parse("${url!}view_myFriends_for_share/"),
        body: {'lid': lid!,'accid':accid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            friendsList = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> shareProfile(String friendId) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    try {
      var response = await http.post(
        Uri.parse("${url!}ShareUserAccount/"),
        body: {
          'lid': lid!,           // My ID (Sender)
          'to': friendId,        // Friend's ID (Receiver)
          'accId': widget.accId, // Account ID being shared
        },
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Account Shared');
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Share this account with...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: friendsList.length,
                  itemBuilder: (context, index) {
                    final friend = friendsList[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(imgurl + friend['photo'])),
                      title: Text(friend['name']),
                      subtitle: Text(friend['email']),
                      trailing: ElevatedButton(
                        onPressed: () => shareProfile(friend['id'].toString()),
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                        child: const Text("Send", style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- SHARED POSTS VIEW PAGE ---
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
    imgurl = pref.getString('imgurl').toString();
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
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(imgurl + post['post'], fit: BoxFit.cover, width: double.infinity, height: 250),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['caption'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(post['description'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        const Divider(),
                        Text("Original Owner: ${post['post_owner']}",
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kPrimaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}