import 'package:flutter/material.dart';
import 'package:task_sync/core/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  AuthService get _authService => AuthService();

  @override
  Widget build(BuildContext context) {
    // --- Color Palette from the Design ---
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF121212);
    const cardBg = Color(0xFF1C1C1E);
    const lightText = Color(0xFF8A8A8E);

    return Scaffold(
      backgroundColor: darkBg,
      // The AppBar is part of the main screen, not the scrollable content.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header Section ---
            _ProfileHeader(primaryGreen: primaryGreen, lightText: lightText),
            const SizedBox(height: 32),

            // --- Personal Information Section ---
            const _SectionHeader(title: 'Personal Information'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  _InfoTile(label: 'Age', value: '28'),
                  _InfoTile(label: 'Gender', value: 'Female'),
                  _InfoTile(label: 'Height', value: '165 cm'),
                  _InfoTile(label: 'Weight', value: '60 kg'),
                  _InfoTile(label: 'Activity Level', value: 'Moderately Active'),
                  _InfoTile(label: 'Dietary Preference', value: 'Balanced', hasDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- App Settings Section ---
            const _SectionHeader(title: 'App Settings'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _NotificationSwitch(lightText: lightText, primaryGreen: primaryGreen),
                  _SettingsTile(title: 'Theme', value: 'Dark', onTap: () {}),
                  _SettingsTile(title: 'Language', value: 'English', hasDivider: false, onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Account Section ---
            const _SectionHeader(title: 'Account'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SettingsTile(title: 'Manage Account', onTap: () {}),
                  _SettingsTile(title: 'Export Data', onTap: () {}),
                  _SettingsTile(
                    title: 'Delete Account',
                    hasDivider: false,
                    onTap: () {},
                    textColor: Colors.redAccent.shade100,
                  ),
                  _SettingsTile(
                    title: 'Logout',
                    hasDivider: false, // Last item in the list
                    textColor: primaryGreen, // A distinct, primary action color
                    onTap: () async {
                      // --- LOGOUT LOGIC GOES HERE ---
                      // In a real app, you would:
                      // 1. Sign the user out from Firebase
                      await _authService.signOut();

                      // 2. Navigate to the LoginScreen and remove all previous
                      // screens from the navigation stack.
                      // if (context.mounted) {
                      //   Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      //     MaterialPageRoute(builder: (context) => const LoginScreen()),
                      //     (route) => false,
                      //   );
                      // }

                      print("Logout button tapped!");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE HELPER WIDGETS ---

/// The top section of the profile screen with avatar, name, and edit button.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.primaryGreen, required this.lightText});

  final Color primaryGreen;
  final Color lightText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 50,
            // In a real app, this would be a NetworkImage
            backgroundImage: AssetImage('assets/avatar_placeholder.png'),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sophia Carter',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: primaryGreen, size: 16),
              const SizedBox(width: 4),
              Text(
                'Premium Member',
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: lightText, fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Joined 2022',
                style: TextStyle(color: lightText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
            label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: lightText.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple header for each section of the profile.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A row for the "Personal Information" section.
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool hasDivider;

  const _InfoTile({
    required this.label,
    required this.value,
    this.hasDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text(value, style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 16)),
            ],
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
          ),
      ],
    );
  }
}

/// A reusable tile for settings and account actions.
class _SettingsTile extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool hasDivider;
  final Color? textColor;

  const _SettingsTile({
    required this.title,
    this.value,
    required this.onTap,
    this.hasDivider = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 16)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(value!, style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 16)),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textColor ?? const Color(0xFF8A8A8E),
                  ),
                ],
              ),
              dense: true,
            ),
            if (hasDivider)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
              ),
          ],
        ),
      ),
    );
  }
}

/// A stateful widget to manage the local state of the notification switch.
class _NotificationSwitch extends StatefulWidget {
  const _NotificationSwitch({required this.lightText, required this.primaryGreen});

  final Color lightText;
  final Color primaryGreen;

  @override
  State<_NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<_NotificationSwitch> {
  bool _isToggled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16)),
          trailing: Switch(
            value: _isToggled,
            onChanged: (value) {
              setState(() {
                _isToggled = value;
              });
            },
            activeTrackColor: widget.primaryGreen,
            inactiveTrackColor: widget.lightText.withOpacity(0.3),
            inactiveThumbColor: widget.lightText,
          ),
          dense: true,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ],
    );
  }
}