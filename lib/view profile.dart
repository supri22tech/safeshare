// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
//
// class ProfilePage extends StatefulWidget {
//   final String lid; // login id
//
//   const ProfilePage({super.key, required this.lid});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//
//   TextEditingController nameController = TextEditingController();
//
//   File? photo;
//   final picker = ImagePicker();
//
//   String baseUrl = "http://YOUR_IP:8000"; // change this
//
//   @override
//   void initState() {
//     super.initState();
//     viewProfile();
//   }
//
//   // 🔹 PICK IMAGE
//   Future pickImage() async {
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         photo = File(picked.path);
//       });
//     }
//   }
//
//   // 🔹 VIEW PROFILE API
//   Future viewProfile() async {
//     var url = Uri.parse("$baseUrl/view_profile");
//     var response = await http.post(url, body: {
//       "lid": widget.lid
//     });
//
//     var jsonData = json.decode(response.body);
//
//     if (jsonData['status'] == "ok") {
//       setState(() {
//         nameController.text = jsonData['name'];
//
//       });
//     }
//   }
//
//   // 🔹 UPDATE PROFILE API
//   Future updateProfile() async {
//     var uri = Uri.parse("$baseUrl/update_profile");
//
//     var request = http.MultipartRequest("POST", uri);
//
//     request.fields['lid'] = widget.lid;
//     request.fields['name'] = nameController.text;
//
//
//     if (photo != null) {
//       request.files.add(await http.MultipartFile.fromPath('photo', photo!.path));
//     }
//
//     var response = await request.send();
//     var res = await http.Response.fromStream(response);
//
//     var jsonData = json.decode(res.body);
//
//     if (jsonData['status'] == "ok") {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Profile Updated")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("My Profile")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           children: [
//
//             // PHOTO
//             GestureDetector(
//               onTap: pickImage,
//               child: CircleAvatar(
//                 radius: 60,
//                 backgroundImage:
//                 photo != null ? FileImage(photo!) : null,
//                 child: photo == null ? const Icon(Icons.camera_alt) : null,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             buildTextField("Name", nameController),
//
//
//             const SizedBox(height: 20),
//
//             ElevatedButton(
//               onPressed: updateProfile,
//               child: const Text("Update Profile"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // User data
  Map<String, dynamic> userData = {};
  String profileImageUrl = "";
  String baseUrl = "";
  String imgUrl = "";

  // Controllers for editing
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  // String selectedGender = "Male";
  DateTime? selectedDob;

  File? _newProfileImage;
  File? _newAadhaarImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    placeController.dispose();
    pincodeController.dispose();
    districtController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // LOAD PROFILE DATA
  // --------------------------------------------------------
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String lid = sh.getString('lid') ?? "";
      baseUrl = sh.getString('url') ?? "";
      imgUrl = sh.getString('imgurl') ?? "";

      if (lid.isEmpty) {
        Fluttertoast.showToast(
          msg: "Session expired. Please login again.",
          backgroundColor: Colors.red,
        );
        return;
      }

      final uri = Uri.parse("${baseUrl}get_user_profile/");
      final response = await http.post(uri, body: {'lid': lid});

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            userData = data['data'];
            profileImageUrl = imgUrl + (userData['photo'] ?? '');

            // Initialize controllers
            nameController.text = userData['name'] ?? '';
            emailController.text = userData['email'] ?? '';
            phoneController.text = userData['phone']?.toString() ?? '';
            placeController.text = userData['place'] ?? '';
            pincodeController.text = userData['pincode']?.toString() ?? '';
            districtController.text = userData['district'] ?? '';
            // selectedGender = userData['gender'] ?? 'Male';

            // Parse DOB
            if (userData['dob'] != null && userData['dob'].isNotEmpty) {
              selectedDob = DateTime.parse(userData['dob']);
            }
          });
        } else {
          Fluttertoast.showToast(
            msg: data['message'] ?? "Failed to load profile",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error loading profile: $e",
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------
  // UPDATE PROFILE
  // --------------------------------------------------------
  Future<void> _updateProfile() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all required fields",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String lid = sh.getString('lid') ?? "";

      final uri = Uri.parse("${baseUrl}update_user_profile/");
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['lid'] = lid;
      request.fields['name'] = nameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['phone'] = phoneController.text.trim();
      request.fields['place'] = placeController.text.trim();
      request.fields['pincode'] = pincodeController.text.trim();
      request.fields['district'] = districtController.text.trim();
      // request.fields['gender'] = selectedGender;

      if (selectedDob != null) {
        request.fields['dob'] = selectedDob!.toIso8601String().split('T')[0];
      }

      // Add profile image if selected
      if (_newProfileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _newProfileImage!.path),
        );
      }

      // Add Aadhaar image if selected
      if (_newAadhaarImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('aadhaar', _newAadhaarImage!.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (data['status'] == 'success') {
        Fluttertoast.showToast(
          msg: "Profile updated successfully!",
          backgroundColor: Colors.green,
        );

        // Update SharedPreferences
        if (data['data']['photo'] != null) {
          sh.setString("uimg", imgUrl + data['data']['photo']);
        }
        sh.setString("uname", nameController.text.trim());

        setState(() {
          _isEditing = false;
          _newProfileImage = null;
          _newAadhaarImage = null;
        });

        _loadProfile(); // Reload profile
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? "Update failed",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating profile: $e",
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isSaving = false);
  }

  // --------------------------------------------------------
  // PICK IMAGE
  // --------------------------------------------------------
  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (type == 'profile') {
          _newProfileImage = File(image.path);
        } else if (type == 'aadhaar') {
          _newAadhaarImage = File(image.path);
        }
      });
    }
  }

  // --------------------------------------------------------
  // SELECT DATE
  // --------------------------------------------------------
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDob = picked);
    }
  }

  // --------------------------------------------------------
  // UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _newProfileImage = null;
                  _newAadhaarImage = null;
                });
                _loadProfile(); // Reset to original data
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header Card
              _buildProfileHeader(),
              const SizedBox(height: 20),

              // Personal Information
              _buildInfoCard(),
              const SizedBox(height: 20),

              // Status Information
              _buildStatusCard(),
              const SizedBox(height: 20),

              // Aadhaar Section
              if (_isEditing || userData['aadhaar'] != null)
                _buildAadhaarCard(),

              if (_isEditing) const SizedBox(height: 20),

              // Save Button
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // PROFILE HEADER CARD
  // --------------------------------------------------------
  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : (profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null) as ImageProvider?,
                  child: profileImageUrl.isEmpty && _newProfileImage == null
                      ? Icon(Icons.person, size: 60, color: Colors.blue.shade600)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage('profile'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userData['name'] ?? 'User Name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userData['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // PERSONAL INFO CARD
  // --------------------------------------------------------
  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            _isEditing
                ? TextField(
              controller: nameController,
              decoration: _inputDecoration("Name", Icons.person),
            )
                : _infoRow(Icons.person, "Name", userData['name']),

            const SizedBox(height: 16),

            // Email
            _isEditing
                ? TextField(
              controller: emailController,
              decoration: _inputDecoration("Email", Icons.email),
              keyboardType: TextInputType.emailAddress,
            )
                : _infoRow(Icons.email, "Email", userData['email']),

            const SizedBox(height: 16),

            // Phone
            _isEditing
                ? TextField(
              controller: phoneController,
              decoration: _inputDecoration("Phone", Icons.phone),
              keyboardType: TextInputType.phone,
            )
                : _infoRow(Icons.phone, "Phone", userData['phone']?.toString()),

            const SizedBox(height: 16),

            // Gender
            // _isEditing
            //     ? DropdownButtonFormField<String>(
            //   value: selectedGender,
            //   decoration: _inputDecoration("Gender", Icons.wc),
            //   items: ['Male', 'Female']
            //       .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            //       .toList(),
            //   onChanged: (val) {
            //     if (val != null) setState(() => selectedGender = val);
            //   },
            // )
            //     : _infoRow(Icons.wc, "Gender", userData['gender']),

            const SizedBox(height: 16),

            // Date of Birth
            _isEditing
                ? GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextField(
                  decoration: _inputDecoration(
                    "Date of Birth",
                    Icons.calendar_today,
                  ),
                  controller: TextEditingController(
                    text: selectedDob != null
                        ? "${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}"
                        : '',
                  ),
                ),
              ),
            )
                : _infoRow(Icons.calendar_today, "Date of Birth",
                userData['dob']?.toString().split(' ')[0]),

            const SizedBox(height: 16),

            // Place
            _isEditing
                ? TextField(
              controller: placeController,
              decoration: _inputDecoration("Place", Icons.location_on),
            )
                : _infoRow(Icons.location_on, "Place", userData['place']),

            const SizedBox(height: 16),

            // District
            _isEditing
                ? TextField(
              controller: districtController,
              decoration: _inputDecoration("District", Icons.location_city),
            )
                : _infoRow(Icons.location_city, "District", userData['district']),

            const SizedBox(height: 16),

            // Pincode
            _isEditing
                ? TextField(
              controller: pincodeController,
              decoration: _inputDecoration("Pincode", Icons.pin_drop),
              keyboardType: TextInputType.number,
            )
                : _infoRow(
                Icons.pin_drop, "Pincode", userData['pincode']?.toString()),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // STATUS CARD
  // --------------------------------------------------------
  Widget _buildStatusCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _statusChip(
              "User Status",
              userData['status'] ?? 'user',
              userData['status'] == 'active' ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _statusChip(
              "Identity Status",
              userData['identity_status'] ?? 'user',
              userData['identity_status'] == 'verified'
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // AADHAAR CARD
  // --------------------------------------------------------
  Widget _buildAadhaarCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Identity Verification",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: () => _pickImage('aadhaar'),
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _newAadhaarImage != null
                      ? "Aadhaar Selected"
                      : "Upload Aadhaar",
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (!_isEditing && userData['aadhaar'] != null)
              _infoRow(Icons.credit_card, "Aadhaar", "Uploaded"),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------
  Widget _infoRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
    );
  }
}