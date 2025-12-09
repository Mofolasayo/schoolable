import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class ProfileViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _supabaseService = locator<SupabaseService>();

  // Profile data
  String name = '';
  String role = '';
  String department = '';
  String avatar = 'assets/images/myImage2.jpg'; // Keep valid asset as fallback
  String? avatarUrl;
  String? userStatus;
  String? userGender;

  Map<String, dynamic>? initialProfile;

  ProfileViewModel({this.initialProfile}) {
    _init();
  }

  Future<void> _init() async {
    // 1. Use passed data immediately (Fastest)
    if (initialProfile != null) {
      name = initialProfile!['full_name'] ?? 'User';
      role = initialProfile!['role'] ?? 'Employee';
      department = initialProfile!['department'] ?? '';
      userStatus = initialProfile!['status'] ?? 'active';
      userGender = initialProfile!['gender'];
      avatarUrl = initialProfile!['avatar_url'];
      // If avatarUrl was passed, we are good. If not, we might need to generate it
      if (avatarUrl == null && (userGender != null || name.isNotEmpty)) {
        final seed =
            initialProfile!['employee_id'] ?? initialProfile!['email'] ?? name;
        avatarUrl = _supabaseService.getAvatarUrl(userGender, seed);
      }
      rebuildUi();
    }

    // 2. Fetch fresh/cached data from service (Robust)
    // Try to get data silently first (from cache)
    final profile = await _supabaseService.getUserProfile();

    if (profile != null) {
      _updateProfileData(profile);
    } else {
      // Only show busy if we really don't have data
      setBusy(true);
      // Force a refresh if cache failed
      final newProfile =
          await _supabaseService.getUserProfile(forceRefresh: true);
      if (newProfile != null) {
        _updateProfileData(newProfile);
      }
      setBusy(false);
    }
  }

  void _updateProfileData(Map<String, dynamic> profile) {
    name = profile['full_name'] ?? 'User';
    role = profile['role'] ?? 'Employee';
    department = profile['department'] ?? '';
    userStatus = profile['status'] ?? 'active';
    userGender = profile['gender'];

    // Generate DiceBear avatar URL
    final seed = profile['employee_id'] ?? profile['email'] ?? name;
    avatarUrl = _supabaseService.getAvatarUrl(userGender, seed);

    rebuildUi();
  }

  Future<void> logout() async {
    // Show confirmation dialog
    final response = await _dialogService.showConfirmationDialog(
      title: 'Logout',
      description: 'Are you sure you want to logout?',
      confirmationTitle: 'Logout',
      cancelTitle: 'Cancel',
    );

    if (response?.confirmed ?? false) {
      setBusy(true);
      try {
        await _supabaseService.signOut();

        // Navigate to login and clear stack
        _nav.clearStackAndShow(Routes.loginView);
      } catch (e) {
        await _dialogService.showDialog(
          title: 'Error',
          description: 'Failed to logout. Please try again.',
        );
      } finally {
        setBusy(false);
      }
    }
  }
}
