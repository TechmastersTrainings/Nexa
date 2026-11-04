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
      backgroundColor: const Color(0xFF0F172A),
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

    setState(() {
      _testing = true;
      _testStatus = null;
    });

    try {
      String testEndpoint = rawUrl;
      if (!testEndpoint.endsWith('/health')) {
        if (testEndpoint.endsWith('/api/v1')) {
          testEndpoint = testEndpoint.replaceAll('/api/v1', '/health');
        } else if (testEndpoint.endsWith('/')) {
          testEndpoint = '${testEndpoint}health';
        } else {
          testEndpoint = '$testEndpoint/health';
        }
      }

      final res = await http.get(Uri.parse(testEndpoint)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isSuccess = true;
          _testStatus = 'Connected: ${data["service"] ?? "Nexa Sentinel"} (Online)';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _testStatus = 'Server replied with HTTP ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _testStatus = 'Connection failed: Unable to reach host';
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

    await AppConstants.setApiBase(rawUrl);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to: ${AppConstants.defaultApiBase}'),
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
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dns_rounded, color: Color(0xFF818CF8), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Server Link',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Switch between Cloud Render and Local Wi-Fi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Presets
          const Text(
            'QUICK PRESETS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _urlController.text = AppConstants.defaultRenderUrl;
                    });
                  },
                  icon: const Icon(Icons.cloud_outlined, size: 16, color: Color(0xFF818CF8)),
                  label: const Text('Render Cloud', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _urlController.text = AppConstants.defaultLocalWifiUrl;
                    });
                  },
                  icon: const Icon(Icons.wifi, size: 16, color: Color(0xFF34D399)),
                  label: const Text('Local Wi-Fi', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // URL Input Field
          const Text(
            'API BASE URL',
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
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              hintText: 'https://your-service.onrender.com/api/v1',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
          ),

          // Test status banner
          if (_testStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF10B981).withOpacity(0.12)
                    : const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.parse(
                  _isSuccess ? '1px solid #10b981' : '1px solid #ef4444',
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testStatus!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
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
                child: TextButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.bolt, size: 16),
                  label: const Text('Test Connection'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAndApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
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
