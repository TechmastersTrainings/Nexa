import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_trigger_provider.dart';
import '../providers/incident_provider.dart';
import '../core/api_service.dart';
import 'contacts_screen.dart';
import 'voice_guardian_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isBackendHealthy = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    setState(() => _checkingHealth = true);
    final healthy = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _isBackendHealthy = healthy;
        _checkingHealth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'NEXA GUARDIAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFFFCA5A5)),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              color: const Color(0xFF6366F1),
              onRefresh: () async {
                await auth.refreshProfile();
                await _checkServerHealth();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _checkingHealth
                                ? 'Checking system link...'
                                : _isBackendHealthy
                                    ? 'PostgreSQL 17 Backend Live'
                                    : 'Server Unreachable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isBackendHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // System Capabilities Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined, color: Color(0xFF67E8F9), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Autonomous Safety Protection Active',
                                style: TextStyle(
                                  color: Color(0xFF67E8F9),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Offline voice trigger recognition (Phase 3) and GPS location telemetry with local offline queue persistence (Phase 4) are armed. Distress events are cached locally and synchronized with PostgreSQL.',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SOS Panic Button & Offline Queue Card
                    Consumer<IncidentProvider>(
                      builder: (context, incProv, _) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFDC2626).withValues(alpha: 0.15),
                                const Color(0xFF0E131F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.emergency, color: Color(0xFFF87171), size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Instant SOS Panic',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  if (incProv.pendingCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        '${incProv.pendingCount} Offline Queued',
                                        style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to immediately record distress telemetry with current GPS coordinates into local durable storage.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.5),
                                ),
                                icon: incProv.isTriggering
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.warning_amber_rounded, size: 22),
                                label: Text(
                                  incProv.isTriggering ? 'Recording Telemetry...' : 'TRIGGER EMERGENCY SOS',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                                ),
                                onPressed: incProv.isTriggering
                                    ? null
                                    : () async {
                                        final auth = context.read<AuthProvider>();
                                        final messenger = ScaffoldMessenger.of(context);
                                        final item = await incProv.triggerEmergency(
                                          token: auth.token,
                                          triggerType: 'manual_sos_button',
                                        );
                                        final dispatched = incProv.lastDispatchedCount;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              dispatched > 0
                                                  ? 'Emergency SOS Broadcast! Lat: ${item.latitude?.toStringAsFixed(4) ?? "N/A"}, Lon: ${item.longitude?.toStringAsFixed(4) ?? "N/A"}. Alerts sent to $dispatched contacts!'
                                                  : 'Emergency Recorded! Lat: ${item.latitude?.toStringAsFixed(4) ?? "N/A"}, Lon: ${item.longitude?.toStringAsFixed(4) ?? "N/A"}. Queued & Synced.',
                                            ),
                                            backgroundColor: const Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                              ),

                              if (incProv.lastLocation != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  incProv.lastLocation!.isUnavailable
                                      ? 'Location Status: ${incProv.lastLocation!.unavailableReason}'
                                      : 'GPS Accuracy: ±${incProv.lastLocation!.accuracyMeters?.toStringAsFixed(1)}m • Timestamp: ${incProv.lastLocation!.timestamp?.toLocal().toString().split(".")[0]}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Guardian Identity Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'G',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Verified Guardian Account',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF1E293B), height: 32),

                          _buildDetailRow('Email Address', user.email),
                          const SizedBox(height: 14),
                          _buildDetailRow('Emergency Phone', user.phoneNumber),
                          const SizedBox(height: 14),
                          _buildDetailRow('Account UUID', user.id, isMonospace: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Responders Management Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.people_alt_outlined, color: Color(0xFF6366F1), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Emergency Responders',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage tiered contacts & SMS broadcast',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ContactsScreen()),
                              );
                            },
                            child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Voice Guardian Action Card (Phase 3)
                    Consumer<VoiceTriggerProvider>(
                      builder: (context, voiceProv, _) {
                        final isGuarding = voiceProv.isListening;
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E131F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isGuarding
                                  ? const Color(0xFF06B6D4).withValues(alpha: 0.5)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isGuarding
                                      ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                                      : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isGuarding ? Icons.mic : Icons.mic_none,
                                  color: isGuarding ? const Color(0xFF67E8F9) : const Color(0xFF94A3B8),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Voice Guardian',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isGuarding
                                                ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                                                : const Color(0xFF1E293B),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isGuarding ? 'ARMED' : 'STANDBY',
                                            style: TextStyle(
                                              color: isGuarding ? const Color(0xFF67E8F9) : const Color(0xFF64748B),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Offline on-device safe word detection',
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isGuarding ? const Color(0xFF06B6D4) : const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const VoiceGuardianScreen()),
                                  );
                                },
                                child: const Text('Open', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Roadmap Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform Progression',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPhaseItem('Phase 1', 'FastAPI & Postgres Foundation', true),
                          _buildPhaseItem('Phase 2', 'Emergency Contacts CRUD & OTP', true),
                          _buildPhaseItem('Phase 3', 'Offline Voice Detection (Vosk)', true),
                          _buildPhaseItem('Phase 4', 'Location Queue & Offline Buffers', true),
                          _buildPhaseItem('Phase 5', 'Twilio Automated Dispatch', true),
                          _buildPhaseItem('Phase 6', 'Live Monitor Companion Dashboard', true),
                          _buildPhaseItem('Phase 7', 'Voice-Stress ML Classification', false, isNext: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFFE2E8F0),
            fontSize: isMonospace ? 12 : 14,
            fontWeight: isMonospace ? FontWeight.w500 : FontWeight.w600,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseItem(String tag, String title, bool isDone, {bool isNext = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : isNext
                      ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                      : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: isDone
                    ? const Color(0xFF6EE7B7)
                    : isNext
                        ? const Color(0xFFA5B4FC)
                        : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDone ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Icon(
            isDone
                ? Icons.check_circle
                : isNext
                    ? Icons.arrow_forward
                    : Icons.radio_button_unchecked,
            color: isDone
                ? const Color(0xFF10B981)
                : isNext
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF475569),
            size: 16,
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E131F),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out from the guardian device?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
            },
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}
