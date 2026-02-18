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

class ViewExpert extends StatefulWidget {
  const ViewExpert({super.key});

  @override
  State<ViewExpert> createState() => _ViewExpertState();
}

class _ViewExpertState extends State<ViewExpert> {
  List<dynamic> expertList = [];
  bool isLoading = true;
  String baseUrl = "";

  @override
  void initState() {
    super.initState();
    fetchExperts();
  }

  Future<void> fetchExperts() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? imgUrl = pref.getString('imgurl'); // Base path for images
    String? lid = pref.getString('lid');

    setState(() {
      baseUrl = imgUrl ?? "";
    });

    try {
      var response = await http.post(
        Uri.parse("${url!}view_expert/"),
        body: {'lid': lid!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            expertList = data['data'];
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
        title: const Text('EXPERTS', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          itemCount: expertList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            return _buildExpertCard(expertList[index]);
          },
        ),
      ),
    );
  }

  Widget _buildExpertCard(dynamic expert) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                baseUrl + expert['photo'], // Using baseUrl
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(expert['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                Text(expert['district'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 8),
                _actionButton("Tips", Icons.lightbulb_outline, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ExpertTipsPage(expert: expert)));
                }),
                const SizedBox(height: 4),
                _actionButton("Reviews", Icons.star_border, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ExpertReviewsPage(expert: expert)));
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}

// --- TIPS PAGE ---
class ExpertTipsPage extends StatefulWidget {
  final dynamic expert;
  const ExpertTipsPage({super.key, required this.expert});

  @override
  State<ExpertTipsPage> createState() => _ExpertTipsPageState();
}

class _ExpertTipsPageState extends State<ExpertTipsPage> {
  List<dynamic> tips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTips();
  }

  Future<void> fetchTips() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    var response = await http.post(
      Uri.parse("${url!}UserViewTips/"),
      body: {'eid': widget.expert['id'].toString()},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        tips = data['data'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tips from ${widget.expert['name']}"), foregroundColor: kPrimaryColor),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.tips_and_updates, color: Colors.amber),
            title: Text(tips[index]['tips']),
            subtitle: Text(tips[index]['details']),
          ),
        ),
      ),
    );
  }
}

// --- REVIEWS PAGE ---
class ExpertReviewsPage extends StatefulWidget {
  final dynamic expert;
  const ExpertReviewsPage({super.key, required this.expert});

  @override
  State<ExpertReviewsPage> createState() => _ExpertReviewsPageState();
}

class _ExpertReviewsPageState extends State<ExpertReviewsPage> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  double avgRating = 0.0;
  String baseUrl = "";
  final TextEditingController reviewCtrl = TextEditingController();
  double userRating = 5.0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? imgUrl = pref.getString('imgurl');
    setState(() => baseUrl = imgUrl ?? "");

    var response = await http.post(
      Uri.parse("${url!}user_view_review/"),
      body: {'eid': widget.expert['id'].toString()},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        reviews = data['data'];
        if (reviews.isNotEmpty) {
          double total = 0;
          for (var r in reviews) total += double.tryParse(r['rating'].toString()) ?? 0;
          avgRating = total / reviews.length;
        }
        isLoading = false;
      });
    }
  }

  Future<void> sendReview() async {
    if (reviewCtrl.text.isEmpty) return;
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    await http.post(Uri.parse("${url!}insert_review/"), body: {
      'lid': lid,
      'Expert': widget.expert['id'].toString(),
      'review': reviewCtrl.text,
      'rating': userRating.toString(),
    });

    reviewCtrl.clear();
    setState(() => userRating = 5.0);
    fetchReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expert Reviews"), foregroundColor: kPrimaryColor),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 30),
                Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];

                // ROBUST PARSING: Handles Strings, Doubles, and Nulls from JSON
                double score = 0.0;
                try {
                  if (review['rating'] != null) {
                    score = double.parse(review['rating'].toString());
                  }
                } catch (e) {
                  score = 0.0;
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(baseUrl + review['user_photo']),
                  ),
                  title: Text(review['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // STAR LOGIC
                      Row(
                        children: List.generate(5, (i) {
                          // If index is 0 and score is 4.5
                          // 0 < 4 is true -> Full Star
                          if (i < score.floor()) {
                            return const Icon(Icons.star, size: 16, color: Colors.amber);
                          }
                          // 4 < 4.5 is true -> Half Star
                          else if (i < score) {
                            return const Icon(Icons.star_half, size: 16, color: Colors.amber);
                          }
                          // Otherwise -> Border Star
                          else {
                            return const Icon(Icons.star_border, size: 16, color: Colors.grey);
                          }
                        }),
                      ),
                      const SizedBox(height: 2),
                      Text(review['review']),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildReviewInput(),
        ],
      ),
    );
  }

  Widget _buildReviewInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => userRating = index + 1.0),
                icon: Icon(index < userRating ? Icons.star : Icons.star_border, color: Colors.amber),
              );
            }),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: reviewCtrl, decoration: const InputDecoration(hintText: "Add a review..."))),
              IconButton(icon: const Icon(Icons.send, color: kPrimaryColor), onPressed: sendReview),
            ],
          ),
        ],
      ),
    );
  }
}