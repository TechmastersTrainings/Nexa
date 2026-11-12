import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_trigger_provider.dart';
import '../providers/incident_provider.dart';
import '../core/api_service.dart';
import '../widgets/server_settings_dialog.dart';
import 'contacts_screen.dart';
import 'voice_guardian_screen.dart';
import 'safety_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  bool _isBackendHealthy = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServerHealthAndSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServerHealthAndSync();
    }
  }

  Future<void> _checkServerHealthAndSync() async {
    if (mounted) setState(() => _checkingHealth = true);
    final healthy = await _apiService.checkHealth();
    if (!mounted) return;

    setState(() {
      _isBackendHealthy = healthy;
      _checkingHealth = false;
    });

    // Whenever cellular connection to Cloud Server is available, flush any pending offline alerts
    if (healthy) {
      final auth = context.read<AuthProvider>();
      final incProv = context.read<IncidentProvider>();
      if (auth.token != null && incProv.pendingCount > 0) {
        final flushed = await incProv.flushOfflineQueue(auth.token!);
        if (flushed > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced $flushed queued emergency alert(s) to Cloud Server over cellular data.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
            icon: const Icon(Icons.cell_tower_rounded, color: Color(0xFFA5B4FC)),
            tooltip: 'Cloud Server Settings',
            onPressed: () async {
              await ServerSettingsDialog.show(context);
              _checkServerHealthAndSync();
            },
          ),
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
                await _checkServerHealthAndSync();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cellular / Cloud Server Status Pill
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
                              color: _isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _checkingHealth
                                  ? 'Connecting over Cellular Data...'
                                  : _isBackendHealthy
                                      ? 'Cloud Safety Server Live (Cellular 4G/5G)'
                                      : 'Zero-Internet Mode Active (GPS + GSM Fallback)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isBackendHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Cellular + Isolated Zone Architecture Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Color(0xFF67E8F9), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cellular Cloud & Isolated Zone Protection',
                                  style: TextStyle(
                                    color: Color(0xFF67E8F9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Emergency triggers operate directly over cellular data to the Cloud Server for instant SMS & guardian dispatch. In remote dead-zones with zero mobile data, satellite GPS locks your location and falls back to direct GSM call & SMS.',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SOS Panic Button & Cellular/GSM Fallback Card
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
                                  const Row(
                                    children: [
                                      Icon(Icons.emergency, color: Color(0xFFF87171), size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Instant SOS Panic',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  if (incProv.pendingCount > 0)
                                    GestureDetector(
                                      onTap: _checkServerHealthAndSync,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          '${incProv.pendingCount} Queued • Tap Sync',
                                          style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Locks hardware GPS, sends SOS to Cloud Server over cellular internet, and prepares direct GSM SMS/Call fallback if mobile internet is unavailable.',
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
                                  incProv.isTriggering ? 'Dispatching SOS & Locking GPS...' : 'TRIGGER EMERGENCY SOS',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                                ),
                                onPressed: incProv.isTriggering
                                    ? null
                                    : () async {
                                        final auth = context.read<AuthProvider>();
                                        final messenger = ScaffoldMessenger.of(context);
                                        final item = await incProv.triggerEmergency(
                                          token: auth.token,
                                          user: auth.user,
                                          triggerType: 'manual_sos_button',
                                          triggerGsmFallbackIfOffline: true,
                                        );
                                        final dispatched = incProv.lastDispatchedCount;
                                        final syncedToServer = incProv.lastSyncedToServer;
                                        final coords = (item.latitude != null && item.longitude != null)
                                            ? '${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}'
                                            : 'GPS Pending';

                                        String msg;
                                        if (syncedToServer && dispatched > 0) {
                                          msg = 'SOS Sent to Cloud Server ($coords)! $dispatched guardian alert(s) dispatched.';
                                        } else if (syncedToServer) {
                                          msg = 'SOS Recorded on Cloud Server ($coords)! Guardian dispatch ready.';
                                        } else {
                                          msg = 'No mobile internet — SOS saved locally ($coords) & GSM emergency SMS launched for auto-sync.';
                                        }

                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: syncedToServer
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFD97706),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                              ),
                              const SizedBox(height: 10),

                              // Direct Cellular Voice Call & Helpline Buttons (Zero Mobile Data Required)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF6EE7B7),
                                        side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.phone_in_talk_outlined, size: 16),
                                      label: const Text('Call Guardian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      onPressed: () => incProv.launchGuardianCall(user: user),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFFCA5A5),
                                        side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.local_police_outlined, size: 16),
                                      label: Text(
                                        'Dial ${user.preferredPoliceHelpline}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () => incProv.launchGuardianCall(
                                        overridePhone: user.preferredPoliceHelpline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (incProv.lastLocation != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  incProv.lastLocation!.isUnavailable
                                      ? 'GPS Status: ${incProv.lastLocation!.unavailableReason}'
                                      : 'GPS Lock: ±${incProv.lastLocation!.accuracyMeters?.toStringAsFixed(1)}m • ${incProv.lastLocation!.timestamp?.toLocal().toString().split(".")[0]}',
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
                                      'Verified Protected Profile',
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
                                child: Text(
                                  auth.isOfflineSession ? 'CACHED' : 'ACTIVE',
                                  style: const TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF1E293B), height: 32),

                          if (user.email.isNotEmpty) ...[
                            _buildDetailRow('Account Email', user.email),
                            const SizedBox(height: 14),
                          ],
                          if (user.phoneNumber.isNotEmpty) ...[
                            _buildDetailRow('Registered Mobile', user.phoneNumber),
                            const SizedBox(height: 14),
                          ],
                          _buildDetailRow(
                            'Primary Guardian',
                            user.emergencyContactPhone != null && user.emergencyContactPhone!.isNotEmpty
                                ? '${user.emergencyContactName ?? "Guardian"} (${user.emergencyContactPhone})'
                                : 'Set in Emergency Responders',
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            'Emergency Helpline',
                            '${user.preferredPoliceHelpline}${user.cityPoliceJurisdiction != null && user.cityPoliceJurisdiction!.isNotEmpty ? " • ${user.cityPoliceJurisdiction}" : ""}',
                          ),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Responders',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage trusted contacts & cloud SMS alerts',
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

                    // Voice Guardian Action Card
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
                                      'Works offline • Calls guardian & logs SOS',
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
                    const SizedBox(height: 16),

                    // Community Safety Map Action Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.map_outlined, color: Color(0xFF38BDF8), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Safety Map',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Safe havens, police booths & route alerts',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SafetyMapScreen()),
                              );
                            },
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Isolated Zone Working Procedure Card
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
                            'Emergency Working Procedure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildStepItem('STEP 1', 'Hardware GPS Coordinate Lock (No Wi-Fi Needed)', true),
                          _buildStepItem('STEP 2', 'Cloud Server SOS & Twilio SMS via Cellular Data', _isBackendHealthy),
                          _buildStepItem('STEP 3', 'Direct GSM Voice Call & SMS Fallback in Dead-Zones', true),
                          _buildStepItem('STEP 4', 'Auto-Sync Queued Alerts When Cellular Returns', true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String tag, String title, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isReady
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: isReady ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            isReady ? Icons.check_circle : Icons.sync_problem,
            color: isReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
