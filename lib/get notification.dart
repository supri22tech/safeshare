import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class Get_notification extends StatefulWidget {
  const Get_notification({super.key, required this.title});
  final String title;

  @override
  State<Get_notification> createState() => _Get_notificationState();
}

class _Get_notificationState extends State<Get_notification> {
  List<dynamic> notificationList = [];
  bool isLoading = true;
  String imgBaseUrl = "";

  @override
  void initState() {
    super.initState();
    view_notification();
  }

  Future<void> view_notification() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url') ?? '';
      imgBaseUrl = sh.getString('imgurl') ?? '';
      String lid = sh.getString('lid') ?? '';

      var response = await http.post(
          Uri.parse(urls + 'view_image_notification/'),
          body: {"lid": lid}
      );

      var jsondata = json.decode(response.body);
      setState(() {
        notificationList = jsondata["data"];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  Future<void> updateStatus(String nid, String action) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url') ?? '';
      String endpoint = action == "accept" ? 'accept_notification/' : 'reject_notification/';

      var response = await http.post(Uri.parse(urls + endpoint), body: {"nid": nid});
      var jsondata = json.decode(response.body);

      Fluttertoast.showToast(msg: jsondata['status'] ?? "Updated");
      view_notification(); // Refresh UI
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS',
            style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.1)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : notificationList.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          physics: const BouncingScrollPhysics(),
          itemCount: notificationList.length,
          itemBuilder: (context, index) => _buildNotificationCard(notificationList[index]),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic item) {
    bool isPending = item['status'].toString().toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imgBaseUrl + item['post']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                "Update: ${item['date']}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: isPending ? Colors.orange : Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "Status: ${item['status']}",
                      style: TextStyle(color: isPending ? Colors.orange : Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (isPending)
              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateStatus(item['id'].toString(), 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Confirm"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => updateStatus(item['id'].toString(), 'reject'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          foregroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Dismiss"),
                      ),
                    ),
                  ],
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
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 10),
          const Text("All caught up!", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}