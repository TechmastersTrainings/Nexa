import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ApiService _apiService = ApiService();
  List<TrustedContact> _contacts = [];
  bool _isLoading = true;
  String? _syncStatus;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();

    // 1. First, load local cached contacts or synthesize from registered Primary Guardian
    List<TrustedContact> localList = await _loadLocalCachedContacts(prefs, auth.user);
    if (mounted) {
      setState(() {
        _contacts = localList;
      });
    }

    // 2. If token is offline or missing, attempt automatic re-authentication in the background
    if (auth.isTokenOffline) {
      await auth.syncOrReauthenticate();
    }

    // 3. Attempt server sync if token is available
    final currentToken = auth.token;
    if (currentToken != null && !auth.isTokenOffline) {
      try {
        final serverContacts = await _apiService.getContacts(currentToken);
        if (serverContacts.isNotEmpty) {
          await _saveLocalContacts(prefs, serverContacts);
          if (mounted) {
            setState(() {
              _contacts = serverContacts;
              _syncStatus = 'Cloud Synced';
            });
          }
        } else if (localList.isNotEmpty) {
          // If server list is empty but local has guardian, sync guardian to server
          for (final c in localList) {
            try {
              await _apiService.addContact(
                currentToken,
                name: c.name,
                phoneNumber: c.phoneNumber,
                relationship: c.relationship,
                priorityOrder: c.priorityOrder,
              );
            } catch (_) {}
          }
          final refreshed = await _apiService.getContacts(currentToken);
          if (refreshed.isNotEmpty && mounted) {
            setState(() {
              _contacts = refreshed;
              _syncStatus = 'Cloud Synced';
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _syncStatus = 'Local Sentinel Active';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _syncStatus = 'Local Sentinel Active';
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<TrustedContact>> _loadLocalCachedContacts(SharedPreferences prefs, UserProfile? user) async {
    final raw = prefs.getString(AppConstants.keyLocalContacts);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List list = jsonDecode(raw);
        final parsed = list.map((e) => TrustedContact.fromJson(e as Map<String, dynamic>)).toList();
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }

    // Fallback: build list from registered Primary Guardian
    final guardianName = user?.emergencyContactName ?? prefs.getString(AppConstants.keyGuardianName) ?? 'Primary Guardian';
    final guardianPhone = user?.emergencyContactPhone ?? prefs.getString(AppConstants.keyGuardianPhone) ?? '9113670127';

    final primary = TrustedContact(
      id: 'guardian-primary-1',
      userId: user?.id ?? 'local-user',
      name: guardianName.isNotEmpty ? guardianName : 'Primary Guardian',
      phoneNumber: guardianPhone,
      relationship: user?.emergencyContactRelation ?? 'Family',
      priorityOrder: 1,
      isVerified: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _saveLocalContacts(prefs, [primary]);
    return [primary];
  }

  Future<void> _saveLocalContacts(SharedPreferences prefs, List<TrustedContact> list) async {
    final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(AppConstants.keyLocalContacts, encoded);
    if (list.isNotEmpty) {
      final primary = list.firstWhere((c) => c.priorityOrder == 1, orElse: () => list.first);
      await prefs.setString(AppConstants.keyGuardianPhone, primary.phoneNumber.trim());
      await prefs.setString(AppConstants.keyGuardianName, primary.name.trim());
    }
  }

  Future<void> _callContact(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (clean.isEmpty) return;
      final Uri telUri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _deleteContact(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contacts.removeWhere((c) => c.id == contactId);
    });
    await _saveLocalContacts(prefs, _contacts);

    final auth = context.read<AuthProvider>();
    if (auth.token != null && !auth.isTokenOffline) {
      try {
        await _apiService.deleteContact(auth.token!, contactId);
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency responder removed.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddContactModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relationship = 'Family';
    int priority = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E131F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Emergency Responder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter trusted responder who will receive instant SMS & live GPS coordinates during emergencies.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contact Full Name',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF07090E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mobile Phone Number',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        hintText: 'e.g. +91 9113670127',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF07090E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: relationship,
                      dropdownColor: const Color(0xFF0E131F),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Relationship',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF07090E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Family', child: Text('Family')),
                        DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                        DropdownMenuItem(value: 'Spouse', child: Text('Spouse / Partner')),
                        DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                        DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                        DropdownMenuItem(value: 'Guardian', child: Text('Legal Guardian')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => relationship = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<int>(
                      initialValue: priority,
                      dropdownColor: const Color(0xFF0E131F),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Priority Tier',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF07090E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Priority 1 (Primary Auto-Call & SMS)')),
                        DropdownMenuItem(value: 2, child: Text('Priority 2 (Secondary SMS Alert)')),
                        DropdownMenuItem(value: 3, child: Text('Priority 3 (Broadcast Backup)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => priority = val);
                      },
                    ),
                    const SizedBox(height: 22),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) return;

                        final prefs = await SharedPreferences.getInstance();
                        final newContact = TrustedContact(
                          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
                          userId: context.read<AuthProvider>().user?.id ?? 'user',
                          name: name,
                          phoneNumber: phone,
                          relationship: relationship,
                          priorityOrder: priority,
                          isVerified: true,
                          createdAt: DateTime.now().toIso8601String(),
                        );

                        setState(() {
                          _contacts.add(newContact);
                          _contacts.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
                        });
                        await _saveLocalContacts(prefs, _contacts);

                        final auth = context.read<AuthProvider>();
                        if (auth.token != null && !auth.isTokenOffline) {
                          try {
                            await _apiService.addContact(
                              auth.token!,
                              name: name,
                              phoneNumber: phone,
                              relationship: relationship,
                              priorityOrder: priority,
                            );
                          } catch (_) {}
                        }

                        if (modalCtx.mounted) {
                          Navigator.of(modalCtx).pop();
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $name to emergency responders!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Responder', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text(
          'Emergency Responders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Color(0xFF7C3AED)),
            tooltip: 'Add Responder',
            onPressed: _showAddContactModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FEATURE GUIDE CARD: How to use Emergency Responders
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          const Color(0xFF0E131F),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFA5B4FC), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'How Emergency Responders Work',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (_syncStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _syncStatus!,
                                  style: const TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildGuideItem(
                          'Priority 1 (Primary Guardian)',
                          'Automatically dialed upon voice safe word trigger or 1-tap SOS. Receives instant SMS with live Google Maps GPS tracking link.',
                        ),
                        const SizedBox(height: 8),
                        _buildGuideItem(
                          'Priority 2 & 3 (Backup Circle)',
                          'Receive automated high-priority emergency SMS alerts with your real-time coordinates, safe home address, and police jurisdiction.',
                        ),
                        const SizedBox(height: 8),
                        _buildGuideItem(
                          'Direct Call Option',
                          'Tap the green phone icon on any responder card below to place an immediate cellular voice call at any time.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Responders List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE RESPONDERS (${_contacts.length})',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddContactModal,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF7C3AED)),
                        label: const Text(
                          'Add New',
                          style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Contacts Cards
                  if (_contacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E131F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, color: Color(0xFF64748B), size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'No Responders Configured',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Add your primary guardian and trusted contacts to receive emergency triggers.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._contacts.map((c) {
                      final isPrimary = c.priorityOrder == 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E131F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPrimary
                                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPrimary
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    color: isPrimary ? const Color(0xFF6EE7B7) : const Color(0xFFA5B4FC),
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPrimary
                                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                              : const Color(0xFF6366F1).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          isPrimary ? 'PRIMARY GUARDIAN' : 'TIER ${c.priorityOrder}',
                                          style: TextStyle(
                                            color: isPrimary ? const Color(0xFF6EE7B7) : const Color(0xFFC7D2FE),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${c.relationship} • ${c.phoneNumber}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Direct Call Button
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk, color: Color(0xFF10B981), size: 22),
                              tooltip: 'Call ${c.name}',
                              onPressed: () => _callContact(c.phoneNumber),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 20),
                              tooltip: 'Remove',
                              onPressed: () => _deleteContact(c.id),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildGuideItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
