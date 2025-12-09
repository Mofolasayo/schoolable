import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'complete_profile_viewmodel.dart';

class CompleteProfileView extends StackedView<CompleteProfileViewModel> {
  final String email;
  final String fullName;

  const CompleteProfileView({
    Key? key,
    required this.email,
    required this.fullName,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, CompleteProfileViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/schoolable_logo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                const Text(
                  'Complete Your Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hi $fullName! Let\'s set up your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: kcTextMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Employee ID Field
                TextField(
                  controller: viewModel.employeeIdController,
                  decoration: InputDecoration(
                    hintText: 'Employee ID (e.g., EMP001)',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                TextField(
                  controller: viewModel.phoneController,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: kcBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcBorderColor),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: viewModel.selectedDepartment,
                      hint: const Text(
                        'Select Department',
                        style: TextStyle(color: kcTextMutedColor, fontSize: 14),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: kcTextMutedColor),
                      items: viewModel.departments.map((String dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child:
                              Text(dept, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: viewModel.setDepartment,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Role Text Field
                TextField(
                  controller: viewModel.roleController,
                  decoration: InputDecoration(
                    hintText: 'Role (e.g., Senior Developer, Team Lead)',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.work_outline,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Date Joined Field
                GestureDetector(
                  onTap: () => viewModel.selectDateJoined(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kcBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kcBorderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: kcTextMutedColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.dateJoined == null
                                ? 'Date Joined Company'
                                : viewModel.formatDate(viewModel.dateJoined!),
                            style: TextStyle(
                              color: viewModel.dateJoined == null
                                  ? kcTextMutedColor
                                  : kcTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (viewModel.dateJoined != null)
                          const Icon(
                            Icons.check_circle,
                            color: kcPrimaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: kcBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcBorderColor),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: viewModel.selectedGender,
                      hint: const Text(
                        'Select Gender',
                        style: TextStyle(color: kcTextMutedColor, fontSize: 14),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: kcTextMutedColor),
                      items: viewModel.genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: viewModel.setGender,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date of Birth Field
                GestureDetector(
                  onTap: () => viewModel.selectDateOfBirth(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kcBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kcBorderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          color: kcTextMutedColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.dateOfBirth == null
                                ? 'Date of Birth'
                                : viewModel.formatDate(viewModel.dateOfBirth!),
                            style: TextStyle(
                              color: viewModel.dateOfBirth == null
                                  ? kcTextMutedColor
                                  : kcTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (viewModel.dateOfBirth != null)
                          const Icon(
                            Icons.check_circle,
                            color: kcPrimaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address Field
                TextField(
                  controller: viewModel.addressController,
                  decoration: InputDecoration(
                    hintText: 'Street Address',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.home_outlined,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: 16),

                // City Field
                TextField(
                  controller: viewModel.cityController,
                  decoration: InputDecoration(
                    hintText: 'City',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.location_city_outlined,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // State Field
                TextField(
                  controller: viewModel.stateController,
                  decoration: InputDecoration(
                    hintText: 'State/Province',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.map_outlined,
                        color: kcTextMutedColor, size: 20),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),


                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        viewModel.isBusy ? null : viewModel.completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: viewModel.isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: kcPrimaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This information helps us set up your account properly',
                          style: TextStyle(
                            fontSize: 13,
                            color: kcPrimaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  CompleteProfileViewModel viewModelBuilder(BuildContext context) =>
      CompleteProfileViewModel(email: email, fullName: fullName);
}
