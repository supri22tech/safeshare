import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Standardized Premium Styles
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class ViewOtherUsers extends StatefulWidget {
  const ViewOtherUsers({super.key});

  @override
  State<ViewOtherUsers> createState() => _ViewOtherUsersState();
}

class _ViewOtherUsersState extends State<ViewOtherUsers> {
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
        Uri.parse("${url!}view_otherusers/"),
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

  Future<void> sendRequest(String otherUserLid) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}send_request/"),
        body: {
          'from_lid': lid!,
          'to_lid': otherUserLid,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request Sent Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the page to update the list
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ViewOtherUsers()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send request")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('DISCOVER PEOPLE',
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
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          itemCount: Djangodata.length,
          itemBuilder: (context, index) {
            final item = Djangodata[index];
            return _buildUserCard(item);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: kPrimaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No new people found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Photo with Ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: kPrimaryColor.withOpacity(0.05),
                backgroundImage: NetworkImage(imgurl + item['photo']),
              ),
            ),
            const SizedBox(width: 15),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 2),
                  Text(item['email'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 12, color: kPrimaryColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(item['phone'], style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      Text("•  ${item['gender']}",
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            ElevatedButton(
              onPressed: () => sendRequest(item['id'].toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text("Add",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}