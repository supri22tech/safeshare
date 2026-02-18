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

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  List<dynamic> complaintList = [];
  bool isLoading = true;
  final TextEditingController complaintCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}user_viewreply/"), // Ensure this matches your Django name
        body: {'lid': lid!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            complaintList = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendComplaint() async {
    if (complaintCtrl.text.isEmpty) return;

    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}insert_complaint/"), // Ensure this matches your Django name
        body: {
          'complaint': complaintCtrl.text,
          'lid': lid!,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        complaintCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint submitted successfully")),
        );
        fetchComplaints(); // Reload list
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
        title: const Text('COMPLAINTS',
            style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.2)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildNewComplaintSection(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : complaintList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: complaintList.length,
                itemBuilder: (context, index) => _buildComplaintCard(complaintList[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewComplaintSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          TextField(
            controller: complaintCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "What is the issue you're facing?",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: sendComplaint,
              icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              label: const Text("SUBMIT COMPLAINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(dynamic item) {
    bool isResolved = item['status'].toString().toLowerCase() == 'resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isResolved ? Colors.green.shade50 : Colors.orange.shade50,
          child: Icon(
            isResolved ? Icons.check_circle_outline : Icons.pending_actions,
            color: isResolved ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(item['complaint'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text("Date: ${item['date']}", style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isResolved ? Colors.green.shade500 : Colors.orange.shade500,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item['reply'].toString().toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text("Reply from Support:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryColor)),
                const SizedBox(height: 4),
                Text(
                  item['reply'] ?? "No reply yet. Our team is investigating your issue.",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: kPrimaryColor.withOpacity(0.1)),
          const SizedBox(height: 10),
          const Text("Everything looks good!", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}