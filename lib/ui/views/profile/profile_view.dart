import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
import 'profile_viewmodel.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  final Map<String, dynamic>? userProfile;
  const ProfileView({Key? key, this.userProfile}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ProfileViewModel viewModel, Widget? child) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcBorderColor),
                  ),
                  child: const Icon(Icons.qr_code_rounded,
                      color: kcTextColor, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Profile Card
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kcBorderColor, width: 1),
                        ),
                        child: viewModel.avatarUrl != null
                            ? ClipOval(
                                child: SvgPicture.network(
                                  viewModel.avatarUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (BuildContext context) =>
                                      Container(
                                          padding: const EdgeInsets.all(30.0),
                                          child:
                                              const CupertinoActivityIndicator(
                                            color: Colors.white,
                                          )),
                                ),
                              )
                            : CircleAvatar(
                                radius: 48,
                                backgroundImage: AssetImage(viewModel.avatar),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kcPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 8),
                  if (viewModel.role.isNotEmpty ||
                      viewModel.department.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (viewModel.role.isNotEmpty)
                          Text(
                            viewModel.role,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kcTextMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (viewModel.role.isNotEmpty &&
                            viewModel.department.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Text('•',
                              style: TextStyle(color: kcTextMutedColor)),
                          const SizedBox(width: 8),
                        ],
                        if (viewModel.department.isNotEmpty)
                          Text(
                            viewModel.department,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kcTextMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Settings Sections
            _buildSectionHeader('Account'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: kcBorderColor),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                    trailing: const _ChipText(label: 'On'),
                  ),
                  const Divider(height: 1, color: kcBorderColor),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Security',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Preferences'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    trailing: const Text(
                      'English (US)',
                      style: TextStyle(color: kcTextMutedColor, fontSize: 13),
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: kcBorderColor),
                  _ProfileMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Appearance',
                    trailing: const Text(
                      'Light',
                      style: TextStyle(color: kcTextMutedColor, fontSize: 13),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: kcBorderColor),
                  _ProfileMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    trailing: const Text(
                      'v1.0.0',
                      style: TextStyle(color: kcTextMutedColor, fontSize: 13),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            InkWell(
              onTap: viewModel.logout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: kcRoseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcRoseColor.withOpacity(0.1)),
                ),
                child: const Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kcRoseColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kcTextMutedColor,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) =>
      ProfileViewModel(initialProfile: userProfile);
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: kcTextColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kcTextColor,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: kcTextMutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kcPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcPrimaryColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kcPrimaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
