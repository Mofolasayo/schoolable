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
        title: const Text(
          'Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kcTextColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: kcTextColor),
          onPressed: viewModel.goBack,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Options Section
              _buildSectionHeader('Authentication'),
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
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        // TODO: Implement change password
                      },
                    ),
                    const Divider(height: 1, color: kcBorderColor),
                    _SecurityMenuItem(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Login',
                      subtitle: 'Use fingerprint or face ID',
                      trailing: Switch(
                        value: false, // Todo: bind to viewmodel
                        onChanged: (value) {
                          // TODO: Toggle biometric
                        },
                        activeColor: kcPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                      icon: Icons.phone_iphone_rounded,
                      title: 'This Device',
                      subtitle: 'Currently active',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                          ),
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
                      onTap: () {
                        // TODO: Implement log out all devices
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Danger Zone Section
              _buildSectionHeader('Danger Zone'),
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
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account',
                      iconColor: kcRoseColor,
                      titleColor: kcRoseColor,
                      onTap: viewModel.isDeleting
                          ? null
                          : viewModel.confirmDeleteAccount,
                      trailing: viewModel.isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kcRoseColor,
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: kcTextMutedColor,
                              size: 20,
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
                  color: kcRoseColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kcRoseColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: kcRoseColor.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deleting your account is permanent. All your data, including attendance records, tasks, and performance history will be permanently removed.',
                        style: TextStyle(
                          color: kcRoseColor.withOpacity(0.9),
                          fontSize: 13,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? kcTextColor,
              size: 22,
            ),
            const SizedBox(width: 16),
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
                        fontSize: 13,
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
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
