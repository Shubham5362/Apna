import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class EditShopView extends ConsumerStatefulWidget {
  final int shopId;

  const EditShopView({super.key, required this.shopId});

  @override
  ConsumerState<EditShopView> createState() => _EditShopViewState();
}

class _EditShopViewState extends ConsumerState<EditShopView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isActive = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'is_active': _isActive,
      };

      final success = await ref
          .read(shopOpsProvider.notifier)
          .updateShop(widget.shopId, data);
      if (mounted) {
        if (success) {
          AppSnackbar.show(
            context,
            message:
                'दुकान की जानकारी अपडेट की गई! (Shop updated successfully)',
          );
          context.go('/shops/${widget.shopId}');
        } else {
          final error = ref.read(shopOpsProvider).error;
          AppSnackbar.show(
            context,
            message: 'अपडेट करने में विफल: $error',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopAsync = ref.watch(shopDetailsProvider(widget.shopId));
    final opsState = ref.watch(shopOpsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('दुकान संपादित करें (Edit Shop)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops/${widget.shopId}'),
        ),
      ),
      body: shopAsync.when(
        data: (shop) {
          if (!_initialized) {
            _nameController.text = shop['name'] ?? '';
            _descController.text = shop['description'] ?? '';
            _isActive = shop['is_active'] ?? true;
            _initialized = true;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _nameController,
                    labelText: 'दुकान का नाम (Shop Name)',
                    hintText: 'उदा. माँ दुर्गा प्रोविजन स्टोर',
                    prefixIcon: Icons.storefront_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'दुकान का नाम आवश्यक है';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  AppTextField(
                    controller: _descController,
                    labelText: 'दुकान का विवरण (Description)',
                    hintText: 'अपनी दुकान के बारे में कुछ बताएं...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SwitchListTile(
                    title: const Text('दुकान सक्रिय है? (Is Shop Active?)'),
                    subtitle: const Text(
                      'निष्क्रिय दुकानों को सार्वजनिक रूप से छिपाया जाता है।',
                    ),
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                    secondary: const Icon(Icons.power_settings_new_rounded),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    text: 'बदलाव सुरक्षित करें (Save Changes)',
                    isLoading: opsState.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
        error: (err, stack) => Center(
          child: Text(
            'Error loading shop: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
