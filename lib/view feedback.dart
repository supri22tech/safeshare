import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add this to pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Standardized Premium Styles
const kPrimaryColor = Color(0xFF0D47A1);
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8FAFF), Color(0xFFE0EAFC)],
);

class AppFeedbackPage extends StatefulWidget {
  const AppFeedbackPage({super.key});

  @override
  State<AppFeedbackPage> createState() => _AppFeedbackPageState();
}

class _AppFeedbackPageState extends State<AppFeedbackPage> {
  List<dynamic> feedbackList = [];
  bool isLoading = true;
  double averageRating = 0.0;
  final TextEditingController feedbackCtrl = TextEditingController();
  double selectedRating = 3.0;
  String imgurl = "";

  @override
  void initState() {
    super.initState();
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    imgurl = pref.getString('imgurl').toString();

    try {
      var response = await http.get(Uri.parse("${url!}view_feedback_content/"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            feedbackList = data['data'];
            // Calculate Average
            if (feedbackList.isNotEmpty) {
              double total = 0;
              for (var item in feedbackList) {
                total += double.parse(item['rating'].toString());
              }
              averageRating = total / feedbackList.length;
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitFeedback() async {
    if (feedbackCtrl.text.isEmpty) return;

    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}insert_feedback/"),
        body: {
          'feedback': feedbackCtrl.text,
          'rating': selectedRating.toString(),
          'lid': lid!,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        feedbackCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
        fetchFeedback(); // Refresh
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
        title: const Text('REVIEWS', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.2)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildRatingDashboard(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: feedbackList.length,
                itemBuilder: (context, index) => _buildFeedbackCard(feedbackList[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFeedbackSheet(),
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.rate_review_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildRatingDashboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: kPrimaryColor)),
              const Text("Average Rating", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            children: [
              RatingBarIndicator(
                rating: averageRating,
                itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Colors.amber),
                itemCount: 5,
                itemSize: 25.0,
              ),
              const SizedBox(height: 4),
              Text("${feedbackList.length} Global Reviews", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(imgurl + item['user_photo']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item['date'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    Text(item['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(item['feedback'], style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
        ],
      ),
    );
  }

  void _showFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Write a Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => selectedRating = rating),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: feedbackCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Share your experience...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    submitFeedback();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Submit Feedback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}