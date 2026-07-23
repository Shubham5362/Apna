import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets/reusable_widgets.dart';

class UserProfileView extends ConsumerStatefulWidget {
  const UserProfileView({super.key});

  @override
  ConsumerState<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends ConsumerState<UserProfileView> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _genderController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _languageController;
  late TextEditingController _timezoneController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _genderController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _countryController = TextEditingController();
    _languageController = TextEditingController();
    _timezoneController = TextEditingController();

    // Fill in default values if profile is already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(userProfileProvider);
      if (profileState.profile != null) {
        _populateFields(profileState.profile!);
      }
    });
  }

  void _populateFields(Map<String, dynamic> profile) {
    _fullNameController.text = profile['full_name'] ?? '';
    _emailController.text = profile['email'] ?? '';
    _genderController.text = profile['gender'] ?? '';
    _dobController.text = profile['date_of_birth'] ?? '';
    _addressController.text = profile['address'] ?? '';
    _cityController.text = profile['city'] ?? '';
    _stateController.text = profile['state'] ?? '';
    _pincodeController.text = profile['pincode'] ?? '';
    _countryController.text = profile['country'] ?? '';
    _languageController.text = profile['preferred_language'] ?? '';
    _timezoneController.text = profile['timezone'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updateData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'gender': _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        'date_of_birth': _dobController.text.trim().isEmpty
            ? null
            : _dobController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        'pincode': _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        'country': _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        'preferred_language': _languageController.text.trim().isEmpty
            ? null
            : _languageController.text.trim(),
        'timezone': _timezoneController.text.trim().isEmpty
            ? null
            : _timezoneController.text.trim(),
      };

      final success = await ref
          .read(userProfileProvider.notifier)
          .updateProfile(updateData);

      if (mounted) {
        if (success) {
          AppSnackbar.show(
            context,
            message:
                'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई! (Profile updated successfully)',
          );
        } else {
          final error = ref.read(userProfileProvider).error;
          AppSnackbar.show(
            context,
            message: 'प्रोफ़ाइल अपडेट विफल: $error',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _uploadMockPhoto() async {
    // Generate a simple mock PNG file byte stream
    final mockPngBytes = List<int>.generate(100, (i) => i);
    final success = await ref
        .read(userProfileProvider.notifier)
        .uploadPhoto(mockPngBytes, 'mock_avatar.png');

    if (mounted) {
      if (success) {
        AppSnackbar.show(
          context,
          message: 'प्रोफ़ाइल तस्वीर अपडेट की गई! (Profile photo updated)',
        );
      } else {
        final error = ref.read(userProfileProvider).error;
        AppSnackbar.show(
          context,
          message: 'तस्वीर अपडेट करने में विफल: $error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    // Listen for changes and update controllers accordingly
    ref.listen<UserProfileState>(userProfileProvider, (previous, next) {
      if (next.profile != null && previous?.profile != next.profile) {
        _populateFields(next.profile!);
      }
    });

    final completionPercent = profile?['completion_percentage'] ?? 0;
    final photoUrl = profile?['profile_photo_url'];

    // Base URL support
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;
    final fullPhotoUrl = photoUrl != null ? '$baseUrl$photoUrl' : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('मेरी प्रोफ़ाइल (User Profile)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(userProfileProvider.notifier).fetchProfile(),
          ),
        ],
      ),
      body: profileState.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar & Upload button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          backgroundImage: fullPhotoUrl != null
                              ? NetworkImage(fullPhotoUrl)
                              : null,
                          child: fullPhotoUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                        FloatingActionButton.small(
                          onPressed: _uploadMockPhoto,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          child: const Icon(Icons.camera_alt_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Completion percentage card
                    Card(
                      elevation: 0,
                      color: isDark
                          ? Colors.grey.shade900
                          : theme.colorScheme.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.m),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'प्रोफ़ाइल पूर्णता (Profile Completion)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$completionPercent%',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            LinearProgressIndicator(
                              value: completionPercent / 100.0,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              color: theme.colorScheme.primary,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.s,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Personal details section label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'व्यक्तिगत जानकारी (Personal Information)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    AppTextField(
                      controller: _fullNameController,
                      labelText: 'पूरा नाम (Full Name)',
                      hintText: 'उदा. राम कुमार',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'पूरा नाम आवश्यक है';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    AppTextField(
                      controller: _emailController,
                      labelText: 'ईमेल (Email - Optional)',
                      hintText: 'ram@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final emailRegExp = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'वैध ईमेल आईडी दर्ज करें';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _genderController,
                            labelText: 'लिंग (Gender)',
                            hintText: 'Male / Female',
                            prefixIcon: Icons.wc_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppTextField(
                            controller: _dobController,
                            labelText: 'जन्म तिथि (DOB)',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icons.calendar_today_rounded,
                            keyboardType: TextInputType.datetime,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final dateRegExp = RegExp(
                                  r'^\d{4}-\d{2}-\d{2}$',
                                );
                                if (!dateRegExp.hasMatch(value.trim())) {
                                  return 'YYYY-MM-DD प्रारूप का उपयोग करें';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Contact & address details section label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'पता और संपर्क (Contact & Address)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    AppTextField(
                      controller: _addressController,
                      labelText: 'पता (Street Address)',
                      hintText: 'मकान नंबर, वार्ड नंबर, गली नंबर',
                      prefixIcon: Icons.home_outlined,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _cityController,
                            labelText: 'शहर (City)',
                            hintText: 'मंडला',
                            prefixIcon: Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppTextField(
                            controller: _stateController,
                            labelText: 'राज्य (State)',
                            hintText: 'मध्य प्रदेश',
                            prefixIcon: Icons.map_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _pincodeController,
                            labelText: 'पिनकोड (Pincode)',
                            hintText: '481661',
                            prefixIcon: Icons.pin_drop_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppTextField(
                            controller: _countryController,
                            labelText: 'देश (Country)',
                            hintText: 'भारत',
                            prefixIcon: Icons.public_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _languageController,
                            labelText: 'भाषा (Language)',
                            hintText: 'Hindi / English',
                            prefixIcon: Icons.language_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppTextField(
                            controller: _timezoneController,
                            labelText: 'समय क्षेत्र (Timezone)',
                            hintText: 'Asia/Kolkata',
                            prefixIcon: Icons.access_time_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Actions Box
                    PrimaryButton(
                      text: 'प्रोफ़ाइल सुरक्षित करें (Save Profile)',
                      isLoading: profileState.isLoading,
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    OutlineButton(
                      text: 'भुगतान इतिहास देखें (Payment History)',
                      icon: Icons.history_rounded,
                      onPressed: () => context.go('/payments/history'),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    if (profileState.error != null)
                      Text(
                        profileState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
