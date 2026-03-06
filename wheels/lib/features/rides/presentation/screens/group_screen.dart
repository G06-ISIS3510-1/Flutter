import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';

enum MessageType { driver, passenger, system }

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.type,
    this.avatarUrl,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? avatarUrl;
}

class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.pickupLocation,
    required this.avatarUrl,
    required this.isDriver,
  });

  final String id;
  final String name;
  final String pickupLocation;
  final String avatarUrl;
  final bool isDriver;
}

class GroupScreen extends StatelessWidget {
  const GroupScreen({required this.rideId, super.key});
  final String rideId;

  @override
  Widget build(BuildContext context) => GroupChatScreen(tripId: rideId);
}

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({required this.tripId, super.key});
  final String tripId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  static const _green = Color(0xFF00D9A3);
  static const _bg = Color(0xFFF8F9FA);
  static const _card = Color(0xFFFFFFFF);
  static const _txt = Color(0xFF1A3A5C);
  static const _muted = Color(0xFF6B7280);
  static const _divider = Color(0xFFE5E7EB);
  static const _input = Color(0xFFF3F4F6);
  static const _driverId = 'driver-1';

  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late List<Participant> _participants;
  late List<Message> _messages;

  bool get _hasText => _messageController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController()
      ..addListener(() => setState(() {}));
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _participants = _mockParticipants();
    _messages = _mockMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passengers = _participants.where((p) => !p.isDriver).length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            _participantsBar(passengers),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Say hi to your passengers!',
                        style: TextStyle(fontFamily: 'Poppins', color: _muted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[_messages.length - 1 - index];
                        if (m.type == MessageType.system) return _systemMsg(m);
                        if (m.type == MessageType.driver) return _driverMsg(m);
                        return _passengerMsg(m);
                      },
                    ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_quickBar(), _inputBar()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A5C), Color(0xFF2D5A8C)],
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.activeRide),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showParticipantsDialog,
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ],
          ),
          const Center(
            child: Text(
              'Trip Chat',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _participantsBar(int passengers) {
    const maxVisible = 5;
    final visible = _participants.take(maxVisible).toList();
    final more = _participants.length - visible.length;
    final baseWidth = (visible.length * 24.0) + 8.0;

    return GestureDetector(
      onTap: _showParticipantsDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: _card,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: more > 0 ? baseWidth + 42 : baseWidth,
              height: 32,
              child: Stack(
                children: [
                  for (int i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * 24.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(visible[i].avatarUrl),
                        ),
                      ),
                    ),
                  if (more > 0)
                    Positioned(
                      left: visible.length * 24.0,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$more',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You + $passengers passengers',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBar() {
    Widget chip(String label, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ActionChip(
          backgroundColor: _input,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: onTap,
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _txt,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip('Share ETA', () => _quick('eta')),
          chip('Share Location', () => _quick('location')),
          chip('Running Late', () => _quick('late')),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _card,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _showAddOptions,
              icon: const Icon(
                Icons.add_circle_outline,
                color: _muted,
                size: 24,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _input,
                  hintText: 'Message passengers...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _hasText ? () => _send(_messageController.text) : null,
              icon: Icon(
                Icons.send_rounded,
                color: _hasText ? _green : const Color(0xFFD1D5DB),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverMsg(Message m) {
    final width = MediaQuery.sizeOf(context).width * 0.75;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  m.text,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _time(m.timestamp),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passengerMsg(Message m) {
    final width = MediaQuery.sizeOf(context).width * 0.75;
    final p = _participants.firstWhere(
      (x) => x.id == m.senderId,
      orElse: () => Participant(
        id: m.senderId,
        name: m.senderName,
        pickupLocation: '',
        avatarUrl: m.avatarUrl ?? '',
        isDriver: false,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _avatarColor(p.id),
            foregroundImage: p.avatarUrl.isEmpty
                ? null
                : NetworkImage(p.avatarUrl),
            child: Text(
              _initials(p.name),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.senderName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _txt,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.10),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      m.text,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: _txt,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _time(m.timestamp),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemMsg(Message m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 14, color: _txt),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  m.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: _txt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Participant> _mockParticipants() => const [
    Participant(
      id: 'driver-1',
      name: 'You',
      pickupLocation: 'Main Campus',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      isDriver: true,
    ),
    Participant(
      id: 'pass-1',
      name: 'Sarah Miller',
      pickupLocation: 'Engineering Building',
      avatarUrl: 'https://i.pravatar.cc/150?img=45',
      isDriver: false,
    ),
    Participant(
      id: 'pass-2',
      name: 'Mike Chen',
      pickupLocation: 'Student Center',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      isDriver: false,
    ),
    Participant(
      id: 'pass-3',
      name: 'Emma Davis',
      pickupLocation: 'Library',
      avatarUrl: 'https://i.pravatar.cc/150?img=28',
      isDriver: false,
    ),
  ];
  List<Message> _mockMessages() {
    final now = DateTime.now();
    return [
      Message(
        id: '1',
        senderId: 'system',
        senderName: 'System',
        text: 'Trip started - Good luck!',
        timestamp: now.subtract(const Duration(minutes: 25)),
        type: MessageType.system,
      ),
      Message(
        id: '2',
        senderId: _driverId,
        senderName: 'You',
        text:
            'Hey everyone! Starting the trip now. First stop: Engineering Building',
        timestamp: now.subtract(const Duration(minutes: 24)),
        type: MessageType.driver,
      ),
      Message(
        id: '3',
        senderId: 'pass-1',
        senderName: 'Sarah Miller',
        text: 'Thanks! I am waiting outside the main entrance',
        timestamp: now.subtract(const Duration(minutes: 23)),
        type: MessageType.passenger,
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
      ),
      Message(
        id: '4',
        senderId: 'pass-2',
        senderName: 'Mike Chen',
        text: 'Great! See you soon',
        timestamp: now.subtract(const Duration(minutes: 22)),
        type: MessageType.passenger,
        avatarUrl: 'https://i.pravatar.cc/150?img=33',
      ),
      Message(
        id: '5',
        senderId: 'system',
        senderName: 'System',
        text: 'Sarah Miller picked up',
        timestamp: now.subtract(const Duration(minutes: 18)),
        type: MessageType.system,
      ),
      Message(
        id: '6',
        senderId: 'pass-1',
        senderName: 'Sarah Miller',
        text: 'Got in safely, thanks!',
        timestamp: now.subtract(const Duration(minutes: 17)),
        type: MessageType.passenger,
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
      ),
      Message(
        id: '7',
        senderId: _driverId,
        senderName: 'You',
        text: 'Heading to Student Center now, Mike be ready!',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: MessageType.driver,
      ),
      Message(
        id: '8',
        senderId: 'pass-2',
        senderName: 'Mike Chen',
        text: 'Got it',
        timestamp: now.subtract(const Duration(minutes: 14)),
        type: MessageType.passenger,
        avatarUrl: 'https://i.pravatar.cc/150?img=33',
      ),
    ];
  }

  String _time(DateTime dt) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(dt), alwaysUse24HourFormat: false);
  }

  String _initials(String name) {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _avatarColor(String id) {
    const palette = [
      Color(0xFF1D4ED8),
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
      Color(0xFF7C3AED),
      Color(0xFF2563EB),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }

  void _toLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(
        Message(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: _driverId,
          senderName: 'You',
          text: t,
          timestamp: DateTime.now(),
          type: MessageType.driver,
        ),
      );
      _messageController.clear();
    });
    _toLatest();
  }

  void _quick(String type) {
    switch (type) {
      case 'eta':
        _send('Arriving in approximately 12 minutes');
        return;
      case 'location':
        _send('I am currently at Student Center');
        return;
      case 'late':
        _send('Running 5-10 minutes late. Thanks for your patience!');
        return;
      default:
        return;
    }
  }

  void _showParticipantsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Trip Participants',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: _txt,
          ),
        ),
        content: SizedBox(
          width: 340,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _participants.length,
            separatorBuilder: (_, index) => const Divider(color: _divider),
            itemBuilder: (context, i) {
              final p = _participants[i];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _avatarColor(p.id),
                    foregroundImage: NetworkImage(p.avatarUrl),
                    child: Text(
                      _initials(p.name),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: _txt,
                              ),
                            ),
                            if (p.isDriver) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star, size: 14, color: _green),
                            ],
                          ],
                        ),
                        Text(
                          p.pickupLocation,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Share Live Location'),
                onTap: () {
                  Navigator.pop(context);
                  _quick('location');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Send Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _send('Photo sharing is not available in demo mode.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Share Arrival Time'),
                onTap: () {
                  Navigator.pop(context);
                  _quick('eta');
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
