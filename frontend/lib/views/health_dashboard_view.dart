import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';

class HealthDashboardView extends ConsumerWidget {
  const HealthDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apna Mandla Health Monitor'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'System Status Check',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      healthState.when(
                        data: (data) {
                          final isHealthy =
                              data['status'] == 'healthy' ||
                              data['status'] == 'ok';
                          final dbStatus = data['database'] ?? 'unknown';
                          final redisStatus = data['redis'] ?? 'unknown';
                          final version = data['version'] ?? 'unknown';

                          return Column(
                            children: [
                              _StatusIndicator(
                                label: 'API Gateway',
                                status: isHealthy ? 'healthy' : 'unhealthy',
                              ),
                              const SizedBox(height: 12),
                              _StatusIndicator(
                                label: 'Database (PostgreSQL)',
                                status: dbStatus,
                              ),
                              const SizedBox(height: 12),
                              _StatusIndicator(
                                label: 'Cache (Redis)',
                                status: redisStatus,
                              ),
                              const Divider(height: 32),
                              Text(
                                'Version: $version',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                        error: (err, stack) => Text(
                          'Connection Error: $err',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        loading: () => const CircularProgressIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(healthCheckProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Simulating being authenticated for demonstration / MVP
                      ref.read(authTokenProvider.notifier).state =
                          'mock_jwt_token';
                      context.go('/profile');
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Go to User Profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final String status;

  const _StatusIndicator({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isOk =
        status.toLowerCase() == 'healthy' ||
        status.toLowerCase() == 'connected' ||
        status.toLowerCase() == 'ok';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isOk ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: isOk ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
