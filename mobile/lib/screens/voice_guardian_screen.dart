import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_trigger_provider.dart';

class VoiceGuardianScreen extends StatefulWidget {
  const VoiceGuardianScreen({super.key});

  @override
  State<VoiceGuardianScreen> createState() => _VoiceGuardianScreenState();
}

class _VoiceGuardianScreenState extends State<VoiceGuardianScreen> {
  final _customPhraseController = TextEditingController();

  @override
  void dispose() {
    _customPhraseController.dispose();
    super.dispose();
  }

  void _showAddPhraseDialog(BuildContext context, VoiceTriggerProvider provider) {
    _customPhraseController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E131F),
        title: const Text('Add Custom Safe Phrase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a distinct phrase you can utter under distress to trigger an emergency alert.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _customPhraseController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. nexa code red',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF07090E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final text = _customPhraseController.text.trim();
              if (text.isNotEmpty) {
                provider.addSafePhrase(text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Phrase'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceTriggerProvider>();
    final isListening = provider.isListening;
    final isCooldown = provider.isCooldown;
    final isDetected = provider.isDetected;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text('Voice Guardian (Phase 3)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Mic Pulse Button and Status
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: provider.toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDetected
                              ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                              : isListening
                                  ? [const Color(0xFF06B6D4), const Color(0xFF6366F1)]
                                  : isCooldown
                                      ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDetected
                                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                : isListening
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.45)
                                    : isCooldown
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.3),
                            blurRadius: isListening ? 30 : 15,
                            spreadRadius: isListening ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isDetected
                              ? Icons.warning_amber_rounded
                              : isListening
                                  ? Icons.mic
                                  : isCooldown
                                      ? Icons.timer_outlined
                                      : Icons.mic_off_outlined,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isDetected
                        ? 'DISTRESS TRIGGER DETECTED'
                        : isListening
                            ? 'ACTIVE GUARDING — LISTENING'
                            : isCooldown
                                ? 'COOLDOWN ACTIVE (${provider.cooldownSeconds}s)'
                                : 'STANDBY MODE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDetected
                          ? const Color(0xFFEF4444)
                          : isListening
                              ? const Color(0xFF67E8F9)
                              : isCooldown
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isListening
                        ? 'Continuous on-device acoustic keyword analysis running.'
                        : isCooldown
                            ? 'Preventing cascading alarms. Cooldown protects responders from duplicate triggers.'
                            : 'Tap circle above to activate on-device background detection.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Last Trigger Event Feedback Card
            if (provider.lastTrigger != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: Color(0xFFF87171), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Trigger Event',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phrase: "${provider.lastTrigger!.matchedPhrase}" • Confidence: ${(provider.lastTrigger!.confidence * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sensor & Privacy Disclosure Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline, color: Color(0xFF6EE7B7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        '100% On-Device Privacy Architecture',
                        style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Microphone frames are processed entirely in local memory using the on-device acoustic model and immediately purged. Audio is NEVER recorded, saved, or uploaded to any cloud server.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Safe Words & Phrases Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0E131F),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Safe Words & Phrases',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 22),
                        tooltip: 'Add Safe Phrase',
                        onPressed: () => _showAddPhraseDialog(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.safePhrases.map((phrase) {
                      return Chip(
                        backgroundColor: const Color(0xFF1E293B),
                        label: Text(
                          phrase,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                        onDeleted: () => provider.removeSafePhrase(phrase),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verification & Acoustic Simulation Test Bench
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0E131F),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acoustic Pipeline Simulation Bench',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Test keyword detection while listening mode is active:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isListening
                            ? () => provider.testAudioInput('help')
                            : null,
                        child: const Text('Test "help"'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isListening
                            ? () => provider.testAudioInput('bachao')
                            : null,
                        child: const Text('Test "bachao"'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isListening
                            ? () => provider.testAudioInput('nexa rescue')
                            : null,
                        child: const Text('Test "nexa rescue"'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
