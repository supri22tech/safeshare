import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InstagramStylePostViewer extends StatefulWidget {
  const InstagramStylePostViewer({super.key});

  @override
  State<InstagramStylePostViewer> createState() => _InstagramStylePostViewerState();
}

class _InstagramStylePostViewerState extends State<InstagramStylePostViewer> with TickerProviderStateMixin {
  List<dynamic> postList = [];
  bool isLoading = true;
  String? baseUrl;
  PageController pageController = PageController();
  int currentIndex = 0;
  bool showHeartAnimation = false;
  AnimationController? heartAnimationController;
  Animation<double>? heartAnimation;

  @override
  void initState() {
    super.initState();
    fetchPosts();
    heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: heartAnimationController!, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    heartAnimationController?.dispose();
    pageController.dispose();
    super.dispose();
  }

  void playHeartAnimation(String postId, String currentStatus) {
    setState(() => showHeartAnimation = true);
    heartAnimationController!.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        heartAnimationController!.reverse();
        setState(() => showHeartAnimation = false);
      });
    });

    // Toggle like if not already liked
    if (currentStatus == "0") {
      toggleLike(postId, currentStatus);
    }
  }

  Future<void> fetchPosts() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    baseUrl = pref.getString('imgurl').toString();

    if (url == null || lid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'view_post/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            postList = data['data'];
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
    }
  }

  Future<void> toggleLike(String postId, String currentStatus) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    try {
      final response = await http.post(
        Uri.parse("${url}android_like/"),
        body: {'lid': lid, 'id': postId},
      );

      if (response.statusCode == 200) {
        fetchPosts(); // Refresh to get updated like status
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  void showCommentsBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }

  void showShareBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : postList.isEmpty
          ? const Center(
        child: Text(
          "No posts found",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: postList.length,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
        },
        itemBuilder: (context, index) {
          final post = postList[index];
          String imageUrl = post['photo'];
          if (baseUrl != null && !imageUrl.startsWith('http')) {
            imageUrl = baseUrl! + imageUrl;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with Double Tap
              GestureDetector(
                onDoubleTap: () {
                  playHeartAnimation(post['id'], post['s']);
                },
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.image, size: 100, color: Colors.white24),
                    );
                  },
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Heart Animation on Double Tap
              if (showHeartAnimation && currentIndex == index)
                Center(
                  child: ScaleTransition(
                    scale: heartAnimation!,
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 120,
                      shadows: [
                        Shadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),

              // Top Bar - User Info
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.cyan,
                      child: Text(
                        post['name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        post['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Section - Caption & Actions
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Caption
                      Text(
                        post['caption'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['description'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Like Button
                          _ActionButton(
                            icon: post['s'] == "0"
                                ? Icons.favorite_border
                                : Icons.favorite,
                            color: post['s'] == "0"
                                ? Colors.white
                                : Colors.red,
                            label: "Like",
                            onTap: () => toggleLike(post['id'], post['s']),
                          ),

                          // Comment Button
                          _ActionButton(
                            icon: Icons.chat_bubble_outline,
                            color: Colors.white,
                            label: "Comment",
                            onTap: () async {
                              final pref = await SharedPreferences.getInstance();
                              pref.setString("pid", post['id']);
                              showCommentsBottomSheet(context, post['id']);
                            },
                          ),

                          // Share Button
                          _ActionButton(
                            icon: Icons.send,
                            color: Colors.white,
                            label: "Share",
                            onTap: () async {
                              final pref = await SharedPreferences.getInstance();
                              pref.setString("pid", post['id']);
                              showShareBottomSheet(context, post['id']);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side - Post Indicator
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.45,
                child: Column(
                  children: List.generate(
                    postList.length,
                        (i) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 8,
                      height: i == currentIndex ? 24 : 8,
                      decoration: BoxDecoration(
                        color: i == currentIndex
                            ? Colors.cyan
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Comments Bottom Sheet
class CommentsBottomSheet extends StatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  List<dynamic> commentList = [];
  bool isLoading = true;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? pid = pref.getString('pid');

    if (url == null || pid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'view_comment/'),
        body: {'pid': pid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            commentList = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addComment() async {
    if (commentController.text.isEmpty) return;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    String pid = sh.getString('pid') ?? "";

    var uri = Uri.parse(url + 'add_comment/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['lid'] = lid;
    request.fields['pid'] = pid;
    request.fields['comment'] = commentController.text;

    var response = await request.send();

    if (response.statusCode == 200) {
      commentController.clear();
      fetchComments(); // Refresh comments
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment added")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Comments",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Comments List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : commentList.isEmpty
                    ? const Center(child: Text("No comments yet"))
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: commentList.length,
                  itemBuilder: (context, index) {
                    final comment = commentList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.cyan.shade100,
                            child: Text(
                              comment['user'][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.cyan.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['user'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['comment'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['date'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Add Comment Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.cyan,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: addComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Share Bottom Sheet
class ShareBottomSheet extends StatefulWidget {
  final String postId;

  const ShareBottomSheet({super.key, required this.postId});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
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

    try {
      var response = await http.post(
        Uri.parse("${url!}view_myFriends/"),
        body: {'lid': lid!},
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
  Future<void> sharePost(String friendId) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    String? pid = pref.getString('pid');

    try {
      var response = await http.post(
        Uri.parse("${url!}share_post/"),
        body: {
          'lid': lid!,
          'to': friendId,
          'post': pid!,
        },
      );

      print(response.statusCode);
      print(response.body);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      Fluttertoast.showToast(msg: 'Shared');
      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Share with friends",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Friends List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : friendsList.isEmpty
                    ? const Center(child: Text("No friends found"))
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: friendsList.length,
                  itemBuilder: (context, index) {
                    final friend = friendsList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(imgurl + friend['photo']),
                          backgroundColor: Colors.cyan.shade100,
                        ),
                        title: Text(
                          friend['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(friend['email']),
                        trailing: ElevatedButton(
                          onPressed: () => sharePost(friend['id'].toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          child: const Text("Send"),
                        ),
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