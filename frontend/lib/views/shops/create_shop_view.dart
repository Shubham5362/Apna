import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class CreateShopView extends ConsumerStatefulWidget {
  const CreateShopView({super.key});

  @override
  ConsumerState<CreateShopView> createState() => _CreateShopViewState();
}

class _CreateShopViewState extends ConsumerState<CreateShopView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

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
      };

      final shop = await ref.read(shopOpsProvider.notifier).createShop(data);
      if (mounted) {
        if (shop != null) {
          AppSnackbar.show(
            context,
            message:
                'दुकान सफलतापूर्वक पंजीकृत की गई! (Shop created successfully)',
          );
          final id = shop['id'] as int;
          context.go('/shops/$id');
        } else {
          final error = ref.read(shopOpsProvider).error;
          AppSnackbar.show(
            context,
            message: 'पंजीकरण विफल: $error',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opsState = ref.watch(shopOpsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('दुकान पंजीकृत करें (Register Shop)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'अपना मांडला में आपकी दुकान!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'कृपया अपनी दुकान का नाम और विवरण नीचे दर्ज करें। आप केवल एक दुकान पंजीकृत कर सकते हैं।',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                hintText:
                    'अपनी दुकान और बेचे जाने वाले सामानों के बारे में बताएं...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'दुकान पंजीकृत करें (Register Shop)',
                isLoading: opsState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
