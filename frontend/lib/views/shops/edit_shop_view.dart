import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/shops/${widget.shopId}');
        } else {
          final error = ref.read(shopOpsProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update shop: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailsProvider(widget.shopId));
    final opsState = ref.watch(shopOpsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop'),
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

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Shop Name',
                          prefixIcon: const Icon(Icons.storefront),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Shop name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Shop Description',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Is Shop Active?'),
                        subtitle: const Text(
                          'Inactive shops are hidden from the public.',
                        ),
                        value: _isActive,
                        onChanged: (val) {
                          setState(() {
                            _isActive = val;
                          });
                        },
                        secondary: const Icon(Icons.power_settings_new),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: opsState.isLoading ? null : _submit,
                          icon: opsState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            opsState.isLoading ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
