import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Professional Blue Theme Constants
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class KidActivityFeed extends StatefulWidget {
  const KidActivityFeed({super.key});

  @override
  State<KidActivityFeed> createState() => _KidActivityFeedState();
}

class _KidActivityFeedState extends State<KidActivityFeed> {
  List<dynamic> activities = [];
  bool isLoading = true;
  String kidName = "Your Kid";
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    loadActivityData();
  }

  // Fetch all types of activity from Django
  Future<void> loadActivityData() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    imgurl = pref.getString('imgurl') ?? "";

    try {
      var res = await http.post(
        Uri.parse("${url!}parent_view_activity/"),
        body: {'lid': lid!},
      );

      if (res.statusCode == 200) {
        var jsonRes = json.decode(res.body);
        if (jsonRes['status'] == 'ok') {
          setState(() {
            activities = jsonRes['data'];
            kidName = jsonRes['kid_name'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading activity: $e");
      setState(() => isLoading = false);
    }
  }

  // UI: Build Activity Icon based on Type
  Widget _buildActivityIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'like': icon = Icons.favorite; color = Colors.red; break;
      case 'comment': icon = Icons.chat_bubble; color = Colors.blue; break;
      case 'post': icon = Icons.add_a_photo; color = Colors.orange; break;
      case 'friend': icon = Icons.person_add; color = Colors.green; break;
      case 'share': icon = Icons.send; color = Colors.purple; break;
      default: icon = Icons.notifications; color = kPrimaryColor;
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // UI: THE PREVIEW MODAL (Instagram Style)
  void _showActivityPreview(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Text("Activity Preview", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 18)),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target User Info
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.1), child: const Icon(Icons.person, color: kPrimaryColor)),
                        const SizedBox(width: 12),
                        Text("Post by ${item['target_owner']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Post Image
                    if (item['image'] != "")
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          item['image'].startsWith('http') ? item['image'] : imgurl + item['image'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 15),

                    // Post Captions
                    Text(item['target_caption'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 5),
                    Text(item['target_desc'] ?? "", style: TextStyle(color: Colors.grey.shade700, height: 1.4)),

                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                    // Specific Kid Interaction Logic
                    const Text("KID'S INTERACTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 10),

                    if (item['type'] == 'comment') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.format_quote, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item['kid_comment'], style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic))),
                          ],
                        ),
                      )
                    ] else if (item['type'] == 'like') ...[
                      const Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Your kid liked this content", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("${kidName.toUpperCase()}'S ACTIVITY",
            style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.1, fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : activities.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 1),
          itemBuilder: (context, index) {
            final item = activities[index];
            return _buildActivityTile(item);
          },
        ),
      ),
    );
  }

  Widget _buildActivityTile(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildActivityIcon(item['type']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      children: [
                        const TextSpan(text: "Your kid ", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: item['description']),
                      ],
                    ),
                  ),
                  Text(item['time'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  // ACTION BUTTON
                  GestureDetector(
                    onTap: () => _showActivityPreview(item),
                    child: const Text("View Details",
                        style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            ),
            // Right Side Thumbnail
            if (item['image'] != "")
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'].startsWith('http') ? item['image'] : imgurl + item['image'],
                  width: 45, height: 45, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: kPrimaryColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("No recent activity found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}