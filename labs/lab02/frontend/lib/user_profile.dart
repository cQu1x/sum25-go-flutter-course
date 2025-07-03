import 'package:flutter/material.dart';
import 'package:lab02_chat/user_service.dart';

// UserProfile displays and updates user info
class UserProfile extends StatefulWidget {
  final UserService
      userService; // Accepts a user service for fetching user info
  const UserProfile({Key? key, required this.userService}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, String>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.userService.fetchUser().then((user) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }).catchError((e) {
      setState(() {
        _error = 'error: ${e.toString()}';
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _user == null
                  ? const Center(child: Text('No user data'))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_user!['name'] ?? '', style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(_user!['email'] ?? '', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
    );
  }
}
