import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class OrderDetailsView extends ConsumerWidget {
  final int orderId;

  const OrderDetailsView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final opsState = ref.watch(orderOpsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          final status = order['status'] as String;
          final totalPrice = order['total_price'] as double;
          final address = order['delivery_address'] as String;
          final dateStr = order['created_at'] as String;
          final items = order['items'] as List<dynamic>? ?? [];

          final date = DateTime.parse(dateStr);
          final formattedDate =
              '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                Card(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Status',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _getStatusIcon(status),
                          size: 36,
                          color: _getStatusColor(status),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Status Card
                Card(
                  color:
                      ((order['payment_status'] ?? 'Pending')
                                      .toString()
                                      .toLowerCase() ==
                                  'success'
                              ? Colors.green
                              : Colors.orange)
                          .withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Status',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (order['payment_status'] ?? 'Pending')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    (order['payment_status'] ?? 'Pending')
                                            .toString()
                                            .toLowerCase() ==
                                        'success'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if ((order['payment_status'] ?? 'Pending')
                                    .toString()
                                    .toLowerCase() !=
                                'success' &&
                            status.toLowerCase() != 'cancelled')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go('/payment/$orderId'),
                            icon: const Icon(Icons.payment),
                            label: const Text('Pay Now'),
                          )
                        else
                          Icon(
                            (order['payment_status'] ?? 'Pending')
                                        .toString()
                                        .toLowerCase() ==
                                    'success'
                                ? Icons.check_circle_outlined
                                : Icons.error_outline,
                            size: 36,
                            color:
                                (order['payment_status'] ?? 'Pending')
                                        .toString()
                                        .toLowerCase() ==
                                    'success'
                                ? Colors.green
                                : Colors.orange,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Order metadata
                Text(
                  'Order Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Placed on: $formattedDate',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Address: $address',
                  style: const TextStyle(fontSize: 15),
                ),
                const Divider(height: 40),

                // Order items
                Text(
                  'Items Purchased',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    final name = item['product_name'] as String;
                    final price = item['price'] as double;
                    final qty = item['quantity'] as int;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$name x $qty',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            '\$${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 40),

                // Total Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price Paid:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),

                // Testing Status Updates (MVP friendly!)
                Text(
                  'Test Order Flow Statuses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusButton(context, ref, 'Pending', status),
                    _buildStatusButton(context, ref, 'Confirmed', status),
                    _buildStatusButton(context, ref, 'Packed', status),
                    _buildStatusButton(context, ref, 'Shipped', status),
                    _buildStatusButton(context, ref, 'Delivered', status),
                    _buildStatusButton(context, ref, 'Cancelled', status),
                  ],
                ),
                if (opsState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    opsState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
        error: (err, stack) => Center(
          child: Text(
            'Error loading order details: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String targetStatus,
    String currentStatus,
  ) {
    final isCurrent = targetStatus.toLowerCase() == currentStatus.toLowerCase();
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrent
            ? _getStatusColor(targetStatus)
            : Colors.grey.shade200,
        foregroundColor: isCurrent ? Colors.white : Colors.black87,
      ),
      onPressed: isCurrent
          ? null
          : () async {
              await ref
                  .read(orderOpsProvider.notifier)
                  .updateStatus(orderId, targetStatus);
            },
      child: Text(targetStatus),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'packed':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
