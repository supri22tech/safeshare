import 'package:flutter/material.dart';
import 'package:safe_share/user_view_my_post.dart';
import 'package:safe_share/user_view_post.dart';
import 'package:safe_share/user_view_profile_share_history.dart';
import 'package:safe_share/view%20feedback.dart';
import 'package:safe_share/view%20profile.dart';
import 'package:safe_share/view%20request.dart';
import 'package:safe_share/viewFriends.dart';
import 'package:safe_share/view_users.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_post.dart';
import 'login.dart';
import 'send_complaint.dart';
import 'send_feedback.dart';
import 'view_expert.dart';
import 'view_parants.dart';
import 'parent/view_post.dart';
import 'complaints.dart';
import 'view_review.dart';
import 'view_shared_content.dart';
import 'get notification.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String userName = "User";
  String userimage = "User";
  String userStatus = "User";
  int _notificationCount = 0;
  int _currentIndex = 0;

  // Professional color scheme
  static const Color primaryBlue = Color(0xFF2C5F8D);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('uname') ?? 'User';
      userimage = prefs.getString('uimg') ?? '';
      userStatus = prefs.getString('ustatus') ?? 'SafeShare Member';
    });
  }

  Future<void> _logout() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(28),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from SafeShare?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: textGrey),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: textGrey),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, color: textDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MyLoginPage(title: 'login page',)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildFeedScreen(),
          _buildExploreScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.explore_outlined, 'Explore', 1),
                _buildAddButton(),
                _buildNavItem(Icons.notifications_outlined, 'Alerts', 3, badge: _notificationCount),
                _buildNavItem(Icons.person_outline_rounded, 'Profile', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {int? badge}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Get_notification(title: '')));
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? primaryBlue : textGrey,
                  size: 26,
                ),
                const SizedBox(height: 4),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: accentGold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StyledAddPostPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFeedScreen() {
    return InstagramStylePostViewer();
  }

  Widget _buildExploreScreen() {
    return Container(
      color: backgroundLight,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Explore',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 26,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: textDark),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildListDelegate([
                _buildExploreCard(
                  'Friends',
                  Icons.people_outline_rounded,
                  const Color(0xFF3B82F6),
                  'Connect with others',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => viewFriends())),
                ),
                _buildExploreCard(
                  'My Posts',
                  Icons.grid_on_outlined,
                  const Color(0xFF8B5CF6),
                  'View your content',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPostsManager())),
                ),
                _buildExploreCard(
                  'Experts',
                  Icons.psychology_outlined,
                  const Color(0xFF10B981),
                  'Get expert advice',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewExpert())),
                ),
                _buildExploreCard(
                  'Parents',
                  Icons.family_restroom_outlined,
                  const Color(0xFFF59E0B),
                  'Parent resources',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewParents())),
                ),
                _buildExploreCard(
                  'Users',
                  Icons.account_circle_outlined,
                  const Color(0xFF06B6D4),
                  'Discover people',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewOtherUsers())),
                ),
                _buildExploreCard(
                  'Requests',
                  Icons.person_add_outlined,
                  const Color(0xFFEC4899),
                  'Pending requests',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => viewRequest())),
                ),
                _buildExploreCard(
                  'View Shared Details',
                  Icons.person_add_outlined,
                  const Color(0xFFEC4899),
                  'Profile Shared',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewSharedAccounts())),
                ),_buildExploreCard(
                  'view profile',
                  Icons.person_add_outlined,
                  const Color(0xFFEC4899),
                  'view and update profile',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage())),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Container(
      color: backgroundLight,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: primaryBlue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: accentGold,
                        // 1. If image exists, set it as the background
                        backgroundImage: userimage.isNotEmpty
                            ? NetworkImage(userimage)
                            : null,
                        // 2. If image exists, child is null. If image is empty, show initials.
                        child: userimage.isEmpty
                            ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userStatus,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.settings_outlined, color: Colors.white),
              //   onPressed: () {},
              // ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileSection('Support & Feedback', [
                  _buildProfileTile(
                    Icons.report_problem_outlined,
                    'Complaints',
                    'Report issues or concerns',
                    const Color(0xFFEF4444),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintPage())),
                  ),
                  const Divider(height: 1, indent: 68),
                  _buildProfileTile(
                    Icons.feedback_outlined,
                    'Feedback',
                    'Share your thoughts',
                    const Color(0xFF3B82F6),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppFeedbackPage())),
                  ),
                ]),
                const SizedBox(height: 20),


                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: textGrey.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textGrey.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}