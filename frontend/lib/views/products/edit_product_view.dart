import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class EditProductView extends ConsumerStatefulWidget {
  final int productId;

  const EditProductView({super.key, required this.productId});

  @override
  ConsumerState<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends ConsumerState<EditProductView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _mrpController;
  late TextEditingController _stockController;
  bool _isActive = true;
  bool _initialized = false;

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
        'is_active': _isActive,
      };

      final success = await ref
          .read(productOpsProvider.notifier)
          .updateProduct(widget.productId, data);
      if (mounted) {
        if (success) {
          AppSnackbar.show(
            context,
            message:
                'उत्पाद की जानकारी अपडेट की गई! (Product updated successfully)',
          );
          context.go('/products/${widget.productId}');
        } else {
          final error = ref.read(productOpsProvider).error;
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
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final opsState = ref.watch(productOpsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('उत्पाद संपादित करें (Edit Product)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products/${widget.productId}'),
        ),
      ),
      body: productAsync.when(
        data: (product) {
          if (!_initialized) {
            _nameController.text = product['name'] ?? '';
            _descController.text = product['description'] ?? '';
            _categoryController.text = product['category'] ?? '';
            _brandController.text = product['brand'] ?? '';
            _priceController.text = (product['price'] ?? 0.0).toString();
            _mrpController.text = (product['mrp'] ?? '').toString();
            _stockController.text = (product['stock'] ?? 0).toString();
            _isActive = product['is_active'] ?? true;
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
                          hintText: 'उदा. Vegetables',
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
                  const SizedBox(height: AppSpacing.m),
                  SwitchListTile(
                    title: const Text('उत्पाद सक्रिय है? (Is Product Active?)'),
                    subtitle: const Text(
                      'निष्क्रिय उत्पादों को खोज सूची से छिपाया जाता है।',
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
            'Error loading product: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
