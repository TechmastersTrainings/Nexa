import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const ServerSettingsDialog(),
      ),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _urlController;
  bool _testing = false;
  String? _testStatus;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConstants.defaultApiBase);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    if (AppConstants.isLocalOrPrivateUrl(rawUrl)) {
      setState(() {
        _isSuccess = false;
        _testStatus = 'Local Wi-Fi addresses are disabled. Use your HTTPS Cloud Server URL for cellular access.';
      });
      return;
    }

    setState(() {
      _testing = true;
      _testStatus = null;
    });

    try {
      String testEndpoint = rawUrl;
      if (!testEndpoint.startsWith('https://') && !testEndpoint.startsWith('http://')) {
        testEndpoint = 'https://$testEndpoint';
      }
      if (!testEndpoint.endsWith('/health')) {
        if (testEndpoint.endsWith('/api/v1')) {
          testEndpoint = '$testEndpoint/health';
        } else if (testEndpoint.endsWith('/')) {
          testEndpoint = '${testEndpoint}api/v1/health';
        } else {
          testEndpoint = '$testEndpoint/api/v1/health';
        }
      }

      final res = await http.get(Uri.parse(testEndpoint)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isSuccess = true;
          _testStatus = 'Connected via Cellular/Cloud: ${data["service"] ?? "Nexa Sentinel"} (Online)';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _testStatus = 'Cloud Server replied with HTTP ${res.statusCode}';
        });
      }
    } catch (_) {
      setState(() {
        _isSuccess = false;
        _testStatus = 'Connection failed: Check your mobile data signal and Cloud URL.';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  Future<void> _saveAndApply() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    if (AppConstants.isLocalOrPrivateUrl(rawUrl)) {
      setState(() {
        _isSuccess = false;
        _testStatus = 'Local Wi-Fi is not supported in isolated areas. Enter an HTTPS Cloud Server URL.';
      });
      return;
    }

    final saved = await AppConstants.setApiBase(rawUrl);
    if (!saved) return;

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloud Server updated: ${AppConstants.defaultApiBase}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cell_tower_rounded, color: Color(0xFF7C3AED), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Server Connection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cellular Mobile Data (4G/5G) -> Cloud Safety Server',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Isolated Area Architecture Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 17, color: Color(0xFF6D28D9)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All emergency alerts and safety telemetry run directly on the Cloud Server over Cellular Internet. In zero-internet dead zones, emergencies queue locally and fall back to direct GSM Call & SMS.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF4C1D95), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Default Preset
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _urlController.text = AppConstants.defaultRenderUrl;
                _testStatus = null;
              });
            },
            icon: const Icon(Icons.cloud_done_outlined, size: 16, color: Color(0xFF7C3AED)),
            label: const Text(
              'Use Default Cloud Server',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // URL Input Field
          const Text(
            'CLOUD SERVER URL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'https://your-cloud-server.onrender.com/api/v1',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
            ),
          ),

          // Test status banner
          if (_testStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testStatus!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSuccess ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                        )
                      : const Icon(Icons.bolt, size: 16, color: Color(0xFF475569)),
                  label: const Text('Test Cloud Link', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAndApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
