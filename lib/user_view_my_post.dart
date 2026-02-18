import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// --- Shared Styles ---
const kPrimaryColor = Color(0xFF0D47A1); // Deep Indigo/Blue
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF0F4F8), Color(0xFFE1E9F1)],
);

class MyPostsManager extends StatefulWidget {
  const MyPostsManager({super.key});

  @override
  State<MyPostsManager> createState() => _MyPostsManagerState();
}

class _MyPostsManagerState extends State<MyPostsManager> {
  List<dynamic> postList = [];
  bool isLoading = true;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    baseUrl = pref.getString('imgurl').toString() + "/media/";

    if (url == null || lid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'view_my_post/'),
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

  Future<void> deletePost(String postId) async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse(url! + 'delete_post/'),
        body: {'lid': lid, 'pid': postId},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted successfully")),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context)=>MyPostsManager()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete post")),
      );
    }
  }

  void showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Delete Post?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deletePost(postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showPostDetails(dynamic post) {
    final pref = SharedPreferences.getInstance();
    pref.then((p) => p.setString("pid", post['id']));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailsSheet(
        post: post,
        baseUrl: baseUrl,
        onDelete: () => showDeleteConfirmation(post['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('MY FEED', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, letterSpacing: 1.5)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : postList.isEmpty
            ? _buildEmptyState()
            : _buildGrid(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const StyledAddPostPage())).then((_) => fetchPosts());
        },
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NEW POST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_outlined, size: 80, color: kPrimaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No posts found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
      itemCount: postList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final post = postList[index];
        String imageUrl = post['photo'];
        if (baseUrl != null && !imageUrl.startsWith('http')) imageUrl = baseUrl! + imageUrl;

        return GestureDetector(
          onTap: () => showPostDetails(post),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['caption'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("View Comments", style: TextStyle(fontSize: 11, color: kPrimaryColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PostDetailsSheet extends StatefulWidget {
  final dynamic post;
  final String? baseUrl;
  final VoidCallback onDelete;
  const PostDetailsSheet({super.key, required this.post, required this.baseUrl, required this.onDelete});

  @override
  State<PostDetailsSheet> createState() => _PostDetailsSheetState();
}

class _PostDetailsSheetState extends State<PostDetailsSheet> {
  List<dynamic> commentList = [];
  bool isLoadingComments = true;
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
    if (url == null || pid == null) return;
    try {
      var response = await http.post(Uri.parse(url + 'view_comment/'), body: {'pid': pid});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') setState(() => commentList = data['data']);
      }
    } finally {
      setState(() => isLoadingComments = false);
    }
  }

  Future<void> addComment() async {
    if (commentController.text.isEmpty) return;
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    String pid = sh.getString('pid') ?? "";
    var request = http.MultipartRequest('POST', Uri.parse(url + 'add_comment/'));
    request.fields['lid'] = lid;
    request.fields['pid'] = pid;
    request.fields['comment'] = commentController.text;
    var response = await request.send();
    if (response.statusCode == 200) {
      commentController.clear();
      fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 15), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(widget.baseUrl! + widget.post['photo'], height: 300, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.post['caption'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent), onPressed: widget.onDelete),
                    ],
                  ),
                  Text(widget.post['description'], style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                  const Divider(height: 40),
                  const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 15),
                  if (isLoadingComments) const Center(child: CircularProgressIndicator()) else ...commentList.map((c) => _commentTile(c)),
                ],
              ),
            ),
            _commentInput(),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: kPrimaryColor, radius: 15, child: Text(c['user'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(c['comment'], style: const TextStyle(fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  Widget _commentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Row(
        children: [
          Expanded(child: TextField(controller: commentController, decoration: InputDecoration(hintText: "Add a comment...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
          const SizedBox(width: 10),
          CircleAvatar(backgroundColor: kPrimaryColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: addComment)),
        ],
      ),
    );
  }
}

class StyledAddPostPage extends StatefulWidget {
  const StyledAddPostPage({super.key});
  @override
  State<StyledAddPostPage> createState() => _StyledAddPostPageState();
}

class _StyledAddPostPageState extends State<StyledAddPostPage> {
  File? _selectedImage;
  final TextEditingController captionController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post"), elevation: 0, backgroundColor: Colors.white, foregroundColor: kPrimaryColor),
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final p = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (p != null) setState(() => _selectedImage = File(p.path));
                },
                child: Container(
                  width: double.infinity, height: 280,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.blue.shade100)),
                  child: _selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 50, color: kPrimaryColor), Text("Select Photo", style: TextStyle(fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(height: 25),
              _textField(captionController, "Caption", Icons.title),
              const SizedBox(height: 15),
              _textField(descriptionController, "Description", Icons.notes, lines: 4),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: isUploading ? null : submit,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("PUBLISH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon, {int lines = 1}) {
    return TextField(
      controller: ctrl, maxLines: lines,
      decoration: InputDecoration(prefixIcon: Icon(icon, color: kPrimaryColor), hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
    );
  }

  Future submit() async {
    if (_selectedImage == null || captionController.text.isEmpty) return;
    setState(() => isUploading = true);
    SharedPreferences sh = await SharedPreferences.getInstance();
    var request = http.MultipartRequest('POST', Uri.parse(sh.getString('url')! + 'post_insert/'));
    request.fields['user'] = sh.getString('lid')!;
    request.fields['caption'] = captionController.text;
    request.fields['description'] = descriptionController.text;
    request.files.add(await http.MultipartFile.fromPath('photo', _selectedImage!.path));
    var res = await request.send();
    if (res.statusCode == 200) Navigator.pop(context);
    setState(() => isUploading = false);
  }
}