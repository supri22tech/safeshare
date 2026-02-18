import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class ViewParents extends StatefulWidget {
  const ViewParents({super.key});

  @override
  State<ViewParents> createState() => _ViewParentsState();
}

class _ViewParentsState extends State<ViewParents> {
  List<dynamic> parentList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchParents();
  }

  Future<void> fetchParents() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    if (url == null || lid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'view_parants/'), // Ensure spelling matches your Django: 'view_parants'
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            parentList = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching parents: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('MY PARENTS',
            style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.2)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : parentList.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          itemCount: parentList.length,
          itemBuilder: (context, index) {
            final parent = parentList[index];
            return _buildParentCard(parent);
          },
        ),
      ),
    );
  }

  Widget _buildParentCard(dynamic parent) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      color: Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Placeholder
            CircleAvatar(
              radius: 30,
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              child: const Icon(Icons.family_restroom, color: kPrimaryColor, size: 30),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parent['name'].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.email_outlined, parent['email']),
                  _infoRow(Icons.phone_android_outlined, parent['phone']),
                  _infoRow(Icons.home_work_outlined, "${parent['Housename']}, ${parent['place']}"),
                  const SizedBox(height: 12),
                  // Contact Button

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("No parents linked yet",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
