import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_trigger_provider.dart';
import '../providers/incident_provider.dart';
import '../services/location_service.dart';
import '../core/api_service.dart';
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

    // Auto-arm Voice Guardian on launch: listening is active by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VoiceTriggerProvider>().autoArmListening();
      }
    });
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
      context.read<VoiceTriggerProvider>().autoArmListening();
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

    // Auto-flush queued alerts to Cloud Server whenever connected
    if (healthy) {
      final auth = context.read<AuthProvider>();
      final incProv = context.read<IncidentProvider>();
      if (auth.token != null && incProv.pendingCount > 0) {
        final flushed = await incProv.flushOfflineQueue(auth.token!);
        if (flushed > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-synced $flushed emergency alert(s) to Cloud Server.'),
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
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'NEXA SENTINEL',
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              color: const Color(0xFF7C3AED),
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
                    // System Status Shield Indicator
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
                              color: _isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isBackendHealthy ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _checkingHealth
                                  ? 'Nexa Defense Shield Armed...'
                                  : _isBackendHealthy
                                      ? 'Cloud Safety Server Live (Cellular Data Active)'
                                      : 'Device Safety Shield Active (GPS & Guardian Auto-Dial Armed)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isBackendHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFA5B4FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SOS Panic Button & Guardian Call Card
                    Consumer<IncidentProvider>(
                      builder: (context, incProv, _) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFDC2626).withValues(alpha: 0.18),
                                const Color(0xFF0E131F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
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
                                'Locks satellite GPS coordinates and sends emergency broadcast over cellular internet. Direct phone call is ready below.',
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
                                  incProv.isTriggering ? 'Broadcasting SOS & GPS...' : 'TRIGGER EMERGENCY SOS',
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
                                            : 'GPS Locked';

                                        String msg;
                                        if (syncedToServer && dispatched > 0) {
                                          msg = 'SOS Broadcast Sent ($coords)! $dispatched responder alert(s) sent.';
                                        } else if (syncedToServer) {
                                          msg = 'SOS Recorded on Cloud Server ($coords).';
                                        } else {
                                          msg = 'SOS Saved Locally ($coords) & Emergency SMS prepared.';
                                        }

                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: const Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                              ),
                              const SizedBox(height: 12),

                              // ONE-TAP DIRECT GUARDIAN CALL (With or Without Microphone Active)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.phone_in_talk, size: 20),
                                label: Text(
                                  user.emergencyContactPhone != null && user.emergencyContactPhone!.isNotEmpty
                                      ? 'CALL GUARDIAN: ${user.emergencyContactName ?? "Primary"} (${user.emergencyContactPhone})'
                                      : 'CALL PRIMARY GUARDIAN (1-TAP)',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                onPressed: () {
                                  context.read<VoiceTriggerProvider>().triggerGuardianCall();
                                },
                              ),
                              const SizedBox(height: 10),

                              // National Police Helpline Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFCA5A5),
                                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.local_police_outlined, size: 16),
                                label: Text(
                                  'Dial Police Emergency (${user.preferredPoliceHelpline})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => incProv.launchGuardianCall(
                                  overridePhone: user.preferredPoliceHelpline,
                                ),
                              ),

                              if (incProv.lastLocation != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  incProv.lastLocation!.isUnavailable
                                      ? 'GPS Status: ${incProv.lastLocation!.unavailableReason}'
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

                    // LIVE GEOLOGICAL LOCATION DISPATCH CARD
                    _GeoLocationDispatchCard(user: user),
                    const SizedBox(height: 20),

                    // SAFE WORD SENTINEL CARD (With or Without Microphone Turned On)
                    Consumer<VoiceTriggerProvider>(
                      builder: (context, voiceProv, _) {
                        final activeSafeWord = (user.safeWordPhrase != null && user.safeWordPhrase!.trim().isNotEmpty)
                            ? user.safeWordPhrase!.trim()
                            : 'help nexa';
                        final isArmed = voiceProv.isListening;

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E131F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isArmed
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isArmed ? Icons.mic : Icons.mic_off_outlined,
                                        color: isArmed ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Safe Word Sentinel',
                                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isArmed
                                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                          : const Color(0xFF64748B).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isArmed ? 'MIC ACTIVE' : 'MIC STANDBY',
                                      style: TextStyle(
                                        color: isArmed ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                                  children: [
                                    const TextSpan(text: 'Saying "'),
                                    TextSpan(
                                      text: activeSafeWord,
                                      style: const TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.w800),
                                    ),
                                    const TextSpan(text: '", "help nexa", or "bachao" automatically calls your primary guardian and broadcasts GPS.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Quick-Trigger Safe Word Without Microphone
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.bolt, size: 18),
                                label: Text(
                                  'TRIGGER "$activeSafeWord" (NO MIC NEEDED)',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                                onPressed: () {
                                  voiceProv.triggerSafeWordEmergency(phrase: activeSafeWord);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Safe word triggered! Dialing guardian ($activeSafeWord)...'),
                                      backgroundColor: const Color(0xFF4F46E5),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Guardian Dossier Card
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
                                      'Protected Sentinel Profile',
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
                                  auth.isOfflineSession ? 'SECURE' : 'ARMED',
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
                          if (user.bloodGroup != null && user.bloodGroup!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildDetailRow('Blood Group', user.bloodGroup!),
                          ],
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
                                  'Tiered contacts & SMS notification list',
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
                                          'Voice Settings',
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
                                      'Acoustic keywords & test bench',
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

class _GeoLocationDispatchCard extends StatefulWidget {
  final UserProfile user;
  const _GeoLocationDispatchCard({required this.user});

  @override
  State<_GeoLocationDispatchCard> createState() => _GeoLocationDispatchCardState();
}

class _GeoLocationDispatchCardState extends State<_GeoLocationDispatchCard> {
  bool _isAcquiring = false;
  LocationData? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    if (!mounted) return;
    setState(() => _isAcquiring = true);
    try {
      final loc = await context.read<IncidentProvider>().fetchCurrentLocation();
      if (mounted) {
        setState(() {
          _location = loc;
          _isAcquiring = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAcquiring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardianName = widget.user.emergencyContactName ?? 'Primary Guardian';
    final guardianPhone = widget.user.emergencyContactPhone ?? '';
    final policeNumber = widget.user.preferredPoliceHelpline;
    final isGpsDisabled = _location?.isUnavailable == true &&
        (_location?.unavailableReason?.contains('disabled') ?? false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.satellite_alt_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Live Geological Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_location != null && !_location!.isUnavailable)
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : isGpsDisabled
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (_location != null && !_location!.isUnavailable)
                      ? 'GPS LOCKED'
                      : isGpsDisabled
                          ? 'GPS OFF'
                          : 'SEARCHING',
                  style: TextStyle(
                    color: (_location != null && !_location!.isUnavailable)
                        ? const Color(0xFF34D399)
                        : isGpsDisabled
                            ? const Color(0xFFF87171)
                            : const Color(0xFF7DD3FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Locks real-time satellite GPS coordinates and dispatches your exact Google Maps pin directly to Guardian or Police via SMS & Server.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 14),

          // GPS Status or Fix Display Box
          if (isGpsDisabled)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: Color(0xFFF87171), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Device location service is turned off.',
                      style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await context.read<IncidentProvider>().openLocationSettings();
                      await Future.delayed(const Duration(seconds: 2));
                      _checkLocation();
                    },
                    child: const Text('Turn On', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
            )
          else if (_location != null && !_location!.isUnavailable && _location!.latitude != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0369A1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_location!.latitude!.toStringAsFixed(6)}°, ${_location!.longitude!.toStringAsFixed(6)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Accuracy: ±${_location!.accuracyMeters?.toStringAsFixed(1)}m • Live Fix Active',
                          style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _isAcquiring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, color: Color(0xFF38BDF8), size: 20),
                    tooltip: 'Refresh Location',
                    onPressed: _isAcquiring ? null : _checkLocation,
                  ),
                ],
              ),
            ),

          // Action 1: Send Live GPS to Guardian
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: _isAcquiring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              guardianPhone.isNotEmpty
                  ? 'SEND LIVE GPS TO $guardianName ($guardianPhone)'
                  : 'SEND LIVE GPS TO PRIMARY GUARDIAN',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            onPressed: _isAcquiring
                ? null
                : () async {
                    setState(() => _isAcquiring = true);
                    final auth = context.read<AuthProvider>();
                    final incProv = context.read<IncidentProvider>();
                    final res = await incProv.dispatchGeologicalLocation(
                      user: widget.user,
                      token: auth.token,
                      targetType: 'guardian',
                    );
                    setState(() {
                      _isAcquiring = false;
                      _location = res['location'] as LocationData?;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['opened'] == true
                              ? 'Emergency SMS prepared with live GPS location link!'
                              : 'Location telemetry logged to cloud safety portal.'),
                          backgroundColor: const Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 10),

          // Action 2: Send Live GPS to Police (112)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.local_police, size: 18),
            label: Text(
              'SEND LIVE GPS TO POLICE ($policeNumber)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            onPressed: _isAcquiring
                ? null
                : () async {
                    setState(() => _isAcquiring = true);
                    final auth = context.read<AuthProvider>();
                    final incProv = context.read<IncidentProvider>();
                    final res = await incProv.dispatchGeologicalLocation(
                      user: widget.user,
                      token: auth.token,
                      targetType: 'police',
                    );
                    setState(() {
                      _isAcquiring = false;
                      _location = res['location'] as LocationData?;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['opened'] == true
                              ? 'Police rescue dispatch prepared with live GPS coordinates!'
                              : 'Police emergency telemetry logged.'),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 10),

          // Quick actions row: WhatsApp Pin & Copy Maps Link
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF34D399),
                    side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text(
                    'WhatsApp Pin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final incProv = context.read<IncidentProvider>();
                    final opened = await incProv.launchWhatsAppEmergencyLocation(user: widget.user);
                    if (!opened && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open WhatsApp. Ensure WhatsApp is installed.'),
                          backgroundColor: Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7DD3FC),
                    side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy Maps Link',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    final loc = _location;
                    if (loc != null && !loc.isUnavailable && loc.latitude != null) {
                      final url = 'https://maps.google.com/?q=${loc.latitude!.toStringAsFixed(6)},${loc.longitude!.toStringAsFixed(6)}';
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied live GPS link to clipboard: $url'),
                          backgroundColor: const Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enable GPS or wait for location fix.'),
                          backgroundColor: Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
