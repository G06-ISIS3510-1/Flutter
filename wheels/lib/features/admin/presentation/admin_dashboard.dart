import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../engagement/presentation/providers/engagement_providers.dart';
import 'providers/ride_conversion_providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String? _selectedUserId;
  bool _isRebuildingRideAnalytics = false;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final rideConversionSummaryAsync = ref.watch(rideConversionSummaryProvider);
    final rideConversionRoutesAsync = ref.watch(rideConversionRoutesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Admin Analytics'),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No hay usuarios disponibles para analizar.'),
            );
          }

          _selectedUserId ??= users.first.uid;
          final selectedUser = users.firstWhere(
            (user) => user.uid == _selectedUserId,
            orElse: () => users.first,
          );

          final summaryAsync = ref.watch(
            engagementSummaryProvider(selectedUser.uid),
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FilterCard(
                users: users,
                selectedUserId: selectedUser.uid,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedUserId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              summaryAsync.when(
                data: (summary) {
                  final counts = _normalizeHourCounts(summary?['hourCounts']);
                  final preferredHour =
                      (summary?['preferredHour'] as num?)?.toInt();
                  final totalConnections = counts.fold<int>(
                    0,
                    (total, count) => total + count,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        user: selectedUser,
                        preferredHour: preferredHour,
                        totalConnections: totalConnections,
                      ),
                      const SizedBox(height: 20),
                      _BarChartCard(
                        counts: counts,
                        preferredHour: preferredHour,
                      ),
                      const SizedBox(height: 20),
                      _RideConversionSection(
                        summaryAsync: rideConversionSummaryAsync,
                        routesAsync: rideConversionRoutesAsync,
                        isRebuilding: _isRebuildingRideAnalytics,
                        onRebuild: _rebuildRideConversionAnalytics,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ErrorCard(message: '$error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorCard(message: '$error'),
      ),
    );
  }

  List<int> _normalizeHourCounts(dynamic rawCounts) {
    final countsMap = Map<String, dynamic>.from(
      rawCounts as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    return List<int>.generate(
      24,
      (hour) => (countsMap['$hour'] as num? ?? 0).toInt(),
    );
  }

  Future<void> _rebuildRideConversionAnalytics() async {
    if (_isRebuildingRideAnalytics) {
      return;
    }

    setState(() {
      _isRebuildingRideAnalytics = true;
    });

    try {
      await ref
          .read(rideConversionAnalyticsAdminServiceProvider)
          .rebuildAnalytics();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ride conversion analytics were rebuilt from the current rides collection.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not rebuild ride conversion analytics: $error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isRebuildingRideAnalytics = false;
        });
      }
    }
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.users,
    required this.selectedUserId,
    required this.onChanged,
  });

  final List<AdminUserOption> users;
  final String selectedUserId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usuario a analizar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedUserId,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF5F8FC),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final user in users)
                DropdownMenuItem<String>(
                  value: user.uid,
                  child: Text('${user.fullName} (${user.role})'),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.user,
    required this.preferredHour,
    required this.totalConnections,
  });

  final AdminUserOption user;
  final int? preferredHour;
  final int totalConnections;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: const TextStyle(
              color: Color(0xFFD9E6F6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(
                label: 'Hora habitual',
                value: preferredHour == null
                    ? 'Sin datos'
                    : '${preferredHour.toString().padLeft(2, '0')}:00',
              ),
              _MetricPill(
                label: 'Conexiones 30 dias',
                value: '$totalConnections',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD9E6F6), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.counts, required this.preferredHour});

  final List<int> counts;
  final int? preferredHour;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conexiones por hora del dia',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ultimos 30 dias. Eje X: hora local del usuario. Eje Y: numero de conexiones unicas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxCount == 0 ? 1 : (maxCount + 1).toDouble(),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour < 0 || hour > 23) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: preferredHour == hour
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: preferredHour == hour
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var hour = 0; hour < counts.length; hour++)
                    BarChartGroupData(
                      x: hour,
                      barRods: [
                        BarChartRodData(
                          toY: counts[hour].toDouble(),
                          width: 10,
                          borderRadius: BorderRadius.circular(6),
                          color: preferredHour == hour
                              ? AppColors.accent
                              : AppColors.secondary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideConversionSection extends StatelessWidget {
  const _RideConversionSection({
    required this.summaryAsync,
    required this.routesAsync,
    required this.isRebuilding,
    required this.onRebuild,
  });

  final AsyncValue<RideConversionSummary?> summaryAsync;
  final AsyncValue<List<RideConversionRouteSummary>> routesAsync;
  final bool isRebuilding;
  final Future<void> Function() onRebuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride conversion efficiency',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Business question: What percentage of published rides end up being completed?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: isRebuilding ? null : onRebuild,
              icon: isRebuilding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                isRebuilding
                    ? 'Rebuilding metrics...'
                    : 'Rebuild from current rides',
              ),
            ),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (summary) {
              if (summary == null) {
                return const Text('No ride conversion analytics available yet.');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AnalyticsMetricCard(
                        label: 'Published rides',
                        value: '${summary.totalPublishedRides}',
                      ),
                      _AnalyticsMetricCard(
                        label: 'Completed rides',
                        value: '${summary.completedRides}',
                      ),
                      _AnalyticsMetricCard(
                        label: 'Completion rate',
                        value:
                            '${(summary.completionRate * 100).toStringAsFixed(1)}%',
                      ),
                      _AnalyticsMetricCard(
                        label: 'Cancellation rate',
                        value:
                            '${(summary.cancellationRate * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _CompactStatusChip(
                        label: 'Open',
                        value: summary.openRides,
                      ),
                      _CompactStatusChip(
                        label: 'In progress',
                        value: summary.inProgressRides,
                      ),
                      _CompactStatusChip(
                        label: 'Completed',
                        value: summary.completedRides,
                      ),
                      _CompactStatusChip(
                        label: 'Cancelled',
                        value: summary.cancelledRides,
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('Could not load ride metrics: $error'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Top routes by completed rides',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          routesAsync.when(
            data: (routes) {
              if (routes.isEmpty) {
                return const Text('No route summaries available yet.');
              }

              return Column(
                children: routes
                    .map(
                      (route) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RouteConversionTile(route: route),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('Could not load route metrics: $error'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatusChip extends StatelessWidget {
  const _CompactStatusChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RouteConversionTile extends StatelessWidget {
  const _RouteConversionTile({required this.route});

  final RideConversionRouteSummary route;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.routeLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Published: ${route.totalPublishedRides} - Completed: ${route.completedRides} - Cancelled: ${route.cancelledRides}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Completion rate: ${(route.completionRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(message),
      ),
    );
  }
}
