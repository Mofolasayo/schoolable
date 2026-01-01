import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _backendService = locator<BackendApiService>();

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
      // Use job_title for display (like "Product Manager"), fallback to role
      role =
          initialProfile!['job_title'] ?? initialProfile!['role'] ?? 'Employee';
      department = initialProfile!['department'] ?? '';
      userStatus = initialProfile!['status'] ?? 'active';
      userGender = initialProfile!['gender'];
      avatarUrl = initialProfile!['avatar_url'];
      // If avatarUrl was passed, we are good. If not, we might need to generate it
      if (avatarUrl == null && (userGender != null || name.isNotEmpty)) {
        final seed =
            initialProfile!['employee_id'] ?? initialProfile!['email'] ?? name;
        avatarUrl = _backendService.getAvatarUrl(userGender, seed);
      }
      rebuildUi();
    }

    // 2. Fetch fresh/cached data from service (Robust)
    // Try to get data silently first (from cache)
    final profile = await _backendService.getUserProfile();

    if (profile != null) {
      _updateProfileData(profile);
    } else {
      // Only show busy if we really don't have data
      setBusy(true);
      // Force a refresh if cache failed
      final newProfile =
          await _backendService.getUserProfile(forceRefresh: true);
      if (newProfile != null) {
        _updateProfileData(newProfile);
      }
      setBusy(false);
    }
  }

  // Current Profile Fields (Added to be explicit)
  String? phone;
  String? address;
  String? city;
  String? state;

  void _updateProfileData(Map<String, dynamic> profile) {
    initialProfile = profile; // Keep initialProfile as master sync if needed
    name = profile['full_name'] ?? 'User';
    // Use job_title for display (like "Product Manager"), fallback to role
    role = profile['job_title'] ?? profile['role'] ?? 'Employee';
    department = profile['department'] ?? '';
    userStatus = profile['status'] ?? 'active';
    userGender = profile['gender'];

    // Update local fields for prefilling
    phone = profile['phone'];
    address = profile['address'];
    city = profile['city'];
    state = profile['state'];

    // Use avatar_url from backend
    avatarUrl = profile['avatar_url'];

    // Fallback: Generate DiceBear avatar URL if not provided by backend
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      final seed = profile['employee_id'] ?? profile['email'] ?? name;
      avatarUrl = _backendService.getAvatarUrl(userGender, seed);
    }

    rebuildUi();
  }

  Future<void> updateProfile({
    String? fullName,
    String? jobTitle,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) async {
    setBusy(true);
    try {
      final updated = await _backendService.updateProfile(
        fullName: fullName,
        jobTitle: jobTitle,
        phone: phone,
        address: address,
        city: city,
        state: state,
      );

      _updateProfileData(updated);

      await _dialogService.showDialog(
        title: 'Success',
        description: 'Profile updated successfully',
      );
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to update profile: $e',
      );
    } finally {
      setBusy(false);
    }
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
        await _backendService.signOut();

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

  // Growth & Learning
  bool _hasCurrentQuarterCertificate = false;
  bool get hasCurrentQuarterCertificate => _hasCurrentQuarterCertificate;

  Future<void> checkCertificateStatus() async {
    // TODO: Implement when API endpoint is ready
    // For now, default to false
    _hasCurrentQuarterCertificate = false;
    notifyListeners();
  }

  void navigateToGrowth() {
    _nav.navigateTo(Routes.growthView);
  }

  void navigateToSecurity() {
    _nav.navigateTo(Routes.securityView);
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setBusy(true);
    try {
      await _backendService.uploadAvatar(image.path);
      // Refresh profile to get new avatar URL
      final newProfile =
          await _backendService.getUserProfile(forceRefresh: true);
      if (newProfile != null) {
        _updateProfileData(newProfile);
      }

      await _dialogService.showDialog(
        title: 'Success',
        description: 'Avatar updated successfully',
      );
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to upload avatar: $e',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> editPersonalInfo() async {
    // Show a custom dialog or bottom sheet for editing
    // For simplicity, we can use a bottom sheet approach here or just navigate to a new view
    // if we had one. Let's assume we want to show a bottom sheet.
    // However, since we don't have the context here easily without a custom dialog builder,
    // we might need to rely on the View to call a function that shows the sheet,
    // OR use the DialogService with a custom variant.
    // Let's implement a simple navigation to a "PersonalInformationView" (which we will create next)
    // _nav.navigateTo(Routes.personalInformationView);
    // Since we can't easily register routes, let's use a workaround or assume the view handles it.
    // Actually, let's just expose the logic and let the View call a method to show the sheet.
  }

  // Method to be called from the View to show the edit sheet
  // Actually, Stacked ViewModel shouldn't depend on UI widgets like BottomSheet directly generally,
  // but we can look for a way.
  // Best way given constraints: Create a separate View class and do manual navigation if needed,
  // or use the Dialog Service setup if we have a form dialog.

  // Let's add the updateProfile logic here reusing the existing one.
}
