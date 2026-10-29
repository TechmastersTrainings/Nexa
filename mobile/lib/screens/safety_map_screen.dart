import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});

  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  final ApiService _api = ApiService();
  final LocationService _locService = LocationService();

  List<Map<String, dynamic>> _zones = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  double _currentLat = 12.9716;
  double _currentLng = 77.5946;

  @override
  void initState() {
    super.initState();
    _loadLocationAndZones();
  }

  Future<void> _loadLocationAndZones() async {
    setState(() => _isLoading = true);
    try {
      final loc = await _locService.getCurrentLocation();
      if (!loc.isUnavailable && loc.latitude != null && loc.longitude != null) {
        _currentLat = loc.latitude!;
        _currentLng = loc.longitude!;
      }

      await _fetchZones();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchZones() async {
    final cat = _selectedCategory == 'all' ? null : _selectedCategory;
    final data = await _api.getSafetyZones(
      lat: _currentLat,
      lng: _currentLng,
      radiusKm: 25.0,
      category: cat,
    );
    if (mounted) {
      setState(() {
        _zones = data;
        _error = null;
      });
    }
  }

  void _showReportDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'poor_lighting';
    int severity = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E131F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Report Hazard or Sanctuary',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title / Landmark',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'poor_lighting', child: Text('Poor Lighting')),
                      DropdownMenuItem(value: 'harassment_hotspot', child: Text('Harassment Hotspot')),
                      DropdownMenuItem(value: 'isolated_route', child: Text('Isolated Route')),
                      DropdownMenuItem(value: 'safe_haven', child: Text('Safe Haven Sanctuary')),
                      DropdownMenuItem(value: 'police_booth', child: Text('Police Assistance Desk')),
                      DropdownMenuItem(value: 'hospital', child: Text('Hospital Emergency Care')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          category = val;
                          if (['safe_haven', 'police_booth', 'hospital'].contains(val)) {
                            severity = 1;
                          } else {
                            severity = 3;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final token = context.read<AuthProvider>().token;
                      if (token == null) return;

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(modalCtx).pop();
                      try {
                        await _api.submitSafetyReport(
                          token,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          category: category,
                          severityLevel: severity,
                          latitude: _currentLat,
                          longitude: _currentLng,
                        );
                        await _fetchZones();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
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
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E131F),
        elevation: 0,
        title: const Text(
          'Community Safety Map',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
            onPressed: _loadLocationAndZones,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report Zone', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showReportDialog,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                'all',
                'poor_lighting',
                'harassment_hotspot',
                'isolated_route',
                'safe_haven',
                'police_booth',
                'hospital',
              ].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      cat.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF080C14) : const Color(0xFF94A3B8),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF38BDF8),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _fetchZones();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : _zones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shield_outlined, size: 48, color: Color(0xFF10B981)),
                            SizedBox(height: 12),
                            Text('No Hazards Nearby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Your current perimeter is clear.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _zones.length,
                        itemBuilder: (context, index) {
                          final zone = _zones[index];
                          final isHaven = (zone['severity_level'] ?? 3) == 1;
                          final category = zone['category'] as String? ?? 'hazard';
                          final dist = zone['distance_km'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E131F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHaven
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isHaven
                                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          color: isHaven ? const Color(0xFF6EE7B7) : const Color(0xFFF87171),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (dist != null)
                                      Text(
                                        '$dist km away',
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  zone['title'] ?? 'Hazard Zone',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                if (zone['description'] != null && (zone['description'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    zone['description'],
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isHaven ? 'Verified Safe Haven' : 'Severity: ${zone['severity_level'] ?? 3}/5 Danger',
                                      style: TextStyle(
                                        color: isHaven ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text('${zone['upvotes'] ?? 0}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
