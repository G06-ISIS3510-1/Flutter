import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../engagement/presentation/providers/engagement_providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

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
