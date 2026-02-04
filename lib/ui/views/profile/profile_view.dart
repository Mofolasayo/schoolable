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
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        color: kcPrimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        child: GestureDetector(
                          onTap: viewModel.pickAndUploadAvatar,
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
                    onTap: () => _showPersonalInfoSheet(context, viewModel),
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
                    onTap: () => viewModel.navigateToSecurity(),
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

            _buildSectionHeader('Growth & Learning'),
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
                    icon: Icons.school_rounded,
                    title: 'Training Certificates',
                    trailing: viewModel.hasCurrentQuarterCertificate
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    onTap: () => viewModel.navigateToGrowth(),
                  ),
                  const Divider(height: 1, color: kcBorderColor),
                  _ProfileMenuItem(
                    icon: Icons.event_available,
                    title: 'Apply for leave',
                   
                    onTap: () => viewModel.navigateToLeave(),
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

void _showPersonalInfoSheet(BuildContext context, ProfileViewModel viewModel) {
  // Prefill using the specific fields we added to ViewModel which are kept in sync
  final fullNameController = TextEditingController(text: viewModel.name);
  final jobTitleController = TextEditingController(text: viewModel.role);
  final phoneController = TextEditingController(text: viewModel.phone ?? '');
  final addressController =
      TextEditingController(text: viewModel.address ?? '');
  final cityController = TextEditingController(text: viewModel.city ?? '');
  final stateController = TextEditingController(text: viewModel.state ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kcTextColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: kcTextMutedColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(
                      'Full Name', fullNameController, TextInputType.name),
                  const SizedBox(height: 16),
                  _buildTextField(
                      'Job Title', jobTitleController, TextInputType.text),
                  const SizedBox(height: 16),
                  _buildTextField(
                      'Phone Number', phoneController, TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Address', addressController,
                      TextInputType.streetAddress),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              'City', cityController, TextInputType.text)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(
                              'State', stateController, TextInputType.text)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                viewModel.updateProfile(
                  fullName: fullNameController.text,
                  jobTitle: jobTitleController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                  city: cityController.text,
                  state: stateController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTextField(
    String label, TextEditingController controller, TextInputType type) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kcTextMutedColor)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          filled: true,
          fillColor: kcBackgroundColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kcBorderColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kcBorderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kcPrimaryColor)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
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
