import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../shared/ui/app_scaffold.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../mock/driver_active_ride_mock.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> get _ride => DriverActiveRideMock.ride;
  List<Map<String, dynamic>> get _passengers => DriverActiveRideMock.passengers;

  late final AnimationController _statusController;
  late final Animation<double> _statusOpacity;
  bool _isRideStarted = false;

  int get _occupiedSeats => _passengers.length;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _statusOpacity = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  void _startRide() {
    if (!_isRideStarted) {
      setState(() {
        _isRideStarted = true;
      });
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('\u00a1Viaje iniciado! Buen camino \ud83d\ude97'),
          backgroundColor: Color(0xFF00D9A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openGroupChat() {
    context.go(AppRoutes.groupByRideId('active-driver-ride'));
  }

  void _endRide() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Viaje finalizado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.go(AppRoutes.dashboard);
  }

  Future<void> _cancelRide() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar viaje'),
          content: const Text(
            '\u00bfSeguro que quieres cancelar este viaje? Esta accion no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar cancelacion'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        return;
      case 1:
        context.go(AppRoutes.activeRide);
        return;
      case 2:
        context.go(AppRoutes.notifications);
        return;
      case 3:
        context.go(AppRoutes.profile);
        return;
      default:
        return;
    }
  }

  String _initials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final seats = _ride['seats'] as int;

    return AppScaffold(
      title: 'Viaje Activo',
      showAppBar: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.muted,
      bottomNavigationBar: _BottomDock(
        isRideStarted: _isRideStarted,
        onStartRide: _startRide,
        onCancelRide: _cancelRide,
        onOpenGroupChat: _openGroupChat,
        onEndRide: _endRide,
        onNavTap: _onBottomNavTap,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1A3A5C),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            _Header(statusOpacity: _statusOpacity),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  _RouteCard(ride: _ride),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pasajeros confirmados',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_occupiedSeats/$seats asientos ocupados',
                          style: const TextStyle(
                            color: Color(0xFF1A3A5C),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  ..._passengers.map((passenger) {
                    final name = passenger['name'] as String;
                    final faculty = passenger['faculty'] as String;
                    final confirmed = passenger['confirmed'] as bool;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: _PassengerCard(
                        initials: _initials(name),
                        name: name,
                        faculty: faculty,
                        confirmed: confirmed,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.statusOpacity});

  final Animation<double> statusOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF2D5A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Viaje Activo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: statusOpacity,
            builder: (context, child) {
              return Opacity(opacity: statusOpacity.value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9A3).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '\u25cf EN CURSO',
                style: TextStyle(
                  color: Color(0xFF00D9A3),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.ride});

  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ruta del viaje',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ETA ${ride['eta']}',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: const [
                  Icon(Icons.trip_origin, color: Color(0xFF00D9A3), size: 18),
                  SizedBox(height: 6),
                  _VerticalDashedLine(height: 22),
                  SizedBox(height: 6),
                  Icon(Icons.location_on, color: Color(0xFF1A3A5C), size: 20),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Origen',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ride['origin'] as String,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Text(
                      'Destino',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ride['destination'] as String,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: _TripInfoPill(
                  label: 'Salida',
                  value: ride['departureTime'] as String,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _TripInfoPill(
                  label: 'Llegada',
                  value: ride['eta'] as String,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({
    required this.initials,
    required this.name,
    required this.faculty,
    required this.confirmed,
  });

  final String initials;
  final String name;
  final String faculty;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2D5A8E),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  faculty,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: confirmed
                  ? const Color(0xFF00D9A3).withValues(alpha: 0.14)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: confirmed
                    ? const Color(0xFF00D9A3)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.check,
              color: confirmed
                  ? const Color(0xFF00D9A3)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.isRideStarted,
    required this.onStartRide,
    required this.onCancelRide,
    required this.onOpenGroupChat,
    required this.onEndRide,
    required this.onNavTap,
  });

  final bool isRideStarted;
  final VoidCallback onStartRide;
  final VoidCallback onCancelRide;
  final VoidCallback onOpenGroupChat;
  final VoidCallback onEndRide;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isRideStarted) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9A3), Color(0xFF00B38B)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onStartRide,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Iniciar Viaje',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    const Text(
                      'Cancelar con poca antelacion puede generar penalizacion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFCA5A5),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: onCancelRide,
                      child: const Text(
                        'Cancelar Viaje',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B89C8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: onOpenGroupChat,
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text(
                        'Open Group Chat',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: onEndRide,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Terminar Viaje',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            BottomNavigationBar(
              currentIndex: 1,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF00D9A3),
              unselectedItemColor: const Color(0xFF94A3B8),
              onTap: onNavTap,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car_outlined),
                  activeIcon: Icon(Icons.directions_car),
                  label: 'Mis Viajes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Mensajes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripInfoPill extends StatelessWidget {
  const _TripInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDashedLine extends StatelessWidget {
  const _VerticalDashedLine({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const dashHeight = 4.0;
    const dashGap = 3.0;
    final dashCount = (height / (dashHeight + dashGap)).floor();

    return SizedBox(
      width: 2,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(dashCount, (_) {
          return Container(
            width: 2,
            height: dashHeight,
            color: const Color(0xFFE2E8F0),
          );
        }),
      ),
    );
  }
}
