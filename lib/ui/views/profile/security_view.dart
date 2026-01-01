import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'security_viewmodel.dart';

class SecurityView extends StackedView<SecurityViewModel> {
  const SecurityView({super.key});

  @override
  Widget builder(
    BuildContext context,
    SecurityViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kcTextColor),
          onPressed: viewModel.goBack,
        ),
        title: const Text(
          'Security',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Options Section
              _buildSectionHeader('Password & Authentication'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                ),
                child: Column(
                  children: [
                    _SecurityMenuItem(
                      icon: Icons.key_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        // TODO: Implement change password
                      },
                    ),
                    const Divider(height: 1, color: kcBorderColor),
                    _SecurityMenuItem(
                      icon: Icons.fingerprint,
                      title: 'Biometric Login',
                      subtitle: 'Use fingerprint or face ID',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {
                          // TODO: Toggle biometric
                        },
                        activeColor: kcPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sessions Section
              _buildSectionHeader('Active Sessions'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                ),
                child: Column(
                  children: [
                    _SecurityMenuItem(
                      icon: Icons.phone_iphone,
                      title: 'This Device',
                      subtitle: 'Currently active',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: kcBorderColor),
                    _SecurityMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out All Devices',
                      subtitle: 'Sign out from all other devices',
                      iconColor: const Color(0xFFF97316),
                      onTap: () {
                        // TODO: Implement log out all devices
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Danger Zone Section
              _buildSectionHeader('Danger Zone', isDestructive: true),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _SecurityMenuItem(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data',
                      iconColor: const Color(0xFFEF4444),
                      titleColor: const Color(0xFFEF4444),
                      onTap: viewModel.isDeleting
                          ? null
                          : viewModel.confirmDeleteAccount,
                      trailing: viewModel.isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFEF4444),
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFEF4444),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warning text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: const Color(0xFFEF4444).withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deleting your account is permanent. All your data, including attendance records, tasks, and performance history will be permanently removed.',
                        style: TextStyle(
                          color: const Color(0xFFEF4444).withOpacity(0.8),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDestructive
              ? const Color(0xFFEF4444)
              : kcTextMutedColor.withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  SecurityViewModel viewModelBuilder(BuildContext context) =>
      SecurityViewModel();
}

class _SecurityMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SecurityMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? kcPrimaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? kcPrimaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? kcTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: kcTextMutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: kcTextMutedColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
