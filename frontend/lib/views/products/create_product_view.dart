import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class CreateProductView extends ConsumerStatefulWidget {
  const CreateProductView({super.key});

  @override
  ConsumerState<CreateProductView> createState() => _CreateProductViewState();
}

class _CreateProductViewState extends ConsumerState<CreateProductView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _mrpController;
  late TextEditingController _stockController;
  int? _selectedShopId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _categoryController = TextEditingController();
    _brandController = TextEditingController();
    _priceController = TextEditingController();
    _mrpController = TextEditingController();
    _stockController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedShopId == null) {
        AppSnackbar.show(
          context,
          message: 'कृपया पहले एक दुकान का चयन करें!',
          isError: true,
        );
        return;
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'mrp': _mrpController.text.trim().isEmpty
            ? null
            : double.parse(_mrpController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'shop_id': _selectedShopId,
      };

      final product = await ref
          .read(productOpsProvider.notifier)
          .createProduct(data);
      if (mounted) {
        if (product != null) {
          AppSnackbar.show(
            context,
            message:
                'उत्पाद सफलतापूर्वक पंजीकृत किया गया! (Product listed successfully)',
          );
          final id = product['id'] as int;
          context.go('/products/$id');
        } else {
          final error = ref.read(productOpsProvider).error;
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
    final shopsAsync = ref.watch(shopsListProvider);
    final opsState = ref.watch(productOpsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('नया उत्पाद जोड़ें (Add Product)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
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
                'नया सामान बेचें!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'ग्राहकों को बेचने के लिए उत्पाद की पूरी जानकारी नीचे दर्ज करें।',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Shop selection
              shopsAsync.when(
                data: (shops) {
                  if (shops.isEmpty) {
                    return Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          children: [
                            const Text(
                              'उत्पाद जोड़ने से पहले आपको एक दुकान पंजीकृत करनी होगी।',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            PrimaryButton(
                              text: 'दुकान पंजीकृत करें',
                              onPressed: () => context.go('/shops/create'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_selectedShopId == null && shops.isNotEmpty) {
                    _selectedShopId = shops[0]['id'] as int;
                  }

                  return DropdownButtonFormField<int?>(
                    value: _selectedShopId,
                    decoration: const InputDecoration(
                      labelText: 'दुकान चुनें (Select Shop)',
                      prefixIcon: Icon(Icons.store),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedShopId = value;
                      });
                    },
                    items: shops.map((shop) {
                      return DropdownMenuItem<int?>(
                        value: shop['id'] as int,
                        child: Text(shop['name'] as String),
                      );
                    }).toList(),
                  );
                },
                error: (err, stack) => const Text('Error loading shops'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                controller: _nameController,
                labelText: 'उत्पाद का नाम (Product Name)',
                hintText: 'उदा. ताजी गोभी / शुद्ध सरसों का तेल',
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'उत्पाद का नाम आवश्यक है';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.m),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _brandController,
                      labelText: 'ब्रांड (Optional)',
                      hintText: 'उदा. पतंजलि',
                      prefixIcon: Icons.branding_watermark_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: AppTextField(
                      controller: _categoryController,
                      labelText: 'श्रेणी (Category)',
                      hintText: 'उदा. Vegetables / Dairy',
                      prefixIcon: Icons.category_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'श्रेणी आवश्यक है';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      labelText: 'कीमत (Price ₹)',
                      hintText: '45.00',
                      prefixIcon: Icons.currency_rupee_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'कीमत आवश्यक है';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'वैध कीमत दर्ज करें';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: AppTextField(
                      controller: _mrpController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      labelText: 'MRP (₹ - Optional)',
                      hintText: '50.00',
                      prefixIcon: Icons.money_off_rounded,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'वैध MRP दर्ज करें';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                labelText: 'स्टॉक मात्रा (Stock Units)',
                hintText: '100',
                prefixIcon: Icons.inventory_2_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'स्टॉक आवश्यक है';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'वैध स्टॉक दर्ज करें';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                controller: _descController,
                labelText: 'उत्पाद विवरण (Description)',
                hintText: 'उत्पाद के फायदे, वजन आदि के बारे में लिखें...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                text: 'उत्पाद जोड़े (List Product)',
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
