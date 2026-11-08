import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/server_settings_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1; // 1, 2, or 3

  // Step 1: Personal Identity & Credentials
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Step 2: Emergency Guardian Network
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  String _guardianRelation = 'Mother';

  // Step 3: Police Sanctuary, Medical & Duress Shield
  final _homeAddressController = TextEditingController();
  final _cityPoliceController = TextEditingController();
  String _bloodGroup = '';
  String _preferredHelpline = '112';
  final _medicalNotesController = TextEditingController();
  final _safeWordController = TextEditingController(text: 'help me nexa');
  bool _policeConsent = true;

  String? _stepError;

  final List<String> _relations = const [
    'Mother',
    'Father',
    'Spouse / Partner',
    'Sister',
    'Brother',
    'Close Friend',
    'Legal Guardian',
  ];

  final List<String> _bloodGroups = const [
    '',
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _homeAddressController.dispose();
    _cityPoliceController.dispose();
    _medicalNotesController.dispose();
    _safeWordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _stepError = null);

    if (_currentStep == 1) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _stepError = "Woman's Full Name is required.");
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        setState(() => _stepError = "Primary mobile phone is required for emergency dispatch.");
        return;
      }
      if (!_emailController.text.contains('@')) {
        setState(() => _stepError = "A valid account email is required.");
        return;
      }
      if (_passwordController.text.length < 8) {
        setState(() => _stepError = "Password must be at least 8 characters.");
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_guardianNameController.text.trim().isEmpty) {
        setState(() => _stepError = "Primary Guardian name is required to ensure immediate SOS response.");
        return;
      }
      if (_guardianPhoneController.text.trim().isEmpty) {
        setState(() => _stepError = "Guardian phone number is required for distress SMS delivery.");
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    setState(() {
      _stepError = null;
      if (_currentStep > 1) _currentStep--;
    });
  }

  Future<void> _submitRegistration() async {
    setState(() => _stepError = null);
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final int? parsedAge = int.tryParse(_ageController.text.trim());

    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      age: parsedAge,
      emergencyContactName: _guardianNameController.text.trim(),
      emergencyContactPhone: _guardianPhoneController.text.trim(),
      emergencyContactRelation: _guardianRelation,
      homeAddress: _homeAddressController.text.trim(),
      cityPoliceJurisdiction: _cityPoliceController.text.trim(),
      preferredPoliceHelpline: _preferredHelpline,
      bloodGroup: _bloodGroup.isNotEmpty ? _bloodGroup : null,
      medicalNotes: _medicalNotesController.text.trim(),
      safeWordPhrase: _safeWordController.text.trim().isNotEmpty
          ? _safeWordController.text.trim()
          : 'help me nexa',
      policeDispatchConsent: _policeConsent,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      setState(() {
        _stepError = auth.errorMessage ?? 'Registration failed. Please verify connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            auth.clearError();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined, color: Color(0xFF64748B)),
            tooltip: 'Server Connection',
            onPressed: () => ServerSettingsDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shield Badge Header
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Color(0xFF7C3AED),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle matching website
              const Text(
                'Women Safety Sentinel Onboarding',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure your multi-layered defense shield, primary guardian lifeline, and police dispatch telemetry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Mode Switcher Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Create Protected Profile',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Registration Preparedness Stepper Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentStep == 1
                              ? 'STEP 1 OF 3: IDENTITY & ACCOUNT'
                              : _currentStep == 2
                                  ? 'STEP 2 OF 3: EMERGENCY GUARDIAN NETWORK'
                                  : 'STEP 3 OF 3: POLICE & MEDICAL RESCUE SHIELD',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          _currentStep == 1
                              ? '35% Protected'
                              : _currentStep == 2
                                  ? '70% Protected'
                                  : '100% Shielded 🛡️',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _currentStep == 3
                                ? const Color(0xFF059669)
                                : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _currentStep == 1
                            ? 0.35
                            : _currentStep == 2
                                ? 0.70
                                : 1.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _currentStep == 3
                              ? const Color(0xFF059669)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error notification banner if any
              if (_stepError != null || auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stepError ?? auth.errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // STEP 1 CONTENT
              if (_currentStep == 1) ...[
                _buildFieldLabel("Woman's Full Name *"),
                _buildTextInput(
                  controller: _fullNameController,
                  hintText: 'e.g. Priya Sharma',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Mobile Phone (SOS Lifeline) *'),
                          _buildTextInput(
                            controller: _phoneController,
                            hintText: '+91 98765 43210',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Age (Rescue ID)'),
                          _buildTextInput(
                            controller: _ageController,
                            hintText: 'e.g. 24',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Account Email *'),
                _buildTextInput(
                  controller: _emailController,
                  hintText: 'priya@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Secure Password *'),
                _buildTextInput(
                  controller: _passwordController,
                  hintText: 'Minimum 8 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Protected with Argon2id cryptographic password hashing.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 20),

                // Step 1 Next Button
                _buildGradientButton(
                  text: 'Next: Emergency Guardian Setup',
                  icon: Icons.arrow_forward,
                  onPressed: _nextStep,
                ),
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(
                            text: 'Sign in here',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // STEP 2 CONTENT
              if (_currentStep == 2) ...[
                // Info Banner matching website
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.group_outlined, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Immediate Guardian Link: When an SOS or vocal distress is detected, Nexa automatically sends an emergency SMS with your live GPS location & audio distress link directly to this guardian.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF065F46),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Primary Emergency Guardian Name *'),
                _buildTextInput(
                  controller: _guardianNameController,
                  hintText: 'e.g. Sunita Sharma (Mother)',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Guardian Mobile Phone *'),
                          _buildTextInput(
                            controller: _guardianPhoneController,
                            hintText: '+91 99887 76655',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Relationship'),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _guardianRelation,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                items: _relations.map((r) {
                                  return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _guardianRelation = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildGradientButton(
                        text: 'Next: Police & Medical',
                        icon: Icons.arrow_forward,
                        onPressed: _nextStep,
                      ),
                    ),
                  ],
                ),
              ],

              // STEP 3 CONTENT
              if (_currentStep == 3) ...[
                // Rose Info Banner matching website
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_police_outlined, color: Color(0xFFE11D48), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Police Dispatch Telemetry: Equips local emergency control rooms (PCR) and first responders with your sanctuary address and rescue profile for rapid dispatch.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9D174D),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Safe Home / Base Address'),
                _buildTextInput(
                  controller: _homeAddressController,
                  hintText: 'e.g. Flat 302, Palm Grove, 12th Main Road',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Local Police Station / City'),
                          _buildTextInput(
                            controller: _cityPoliceController,
                            hintText: 'e.g. Koramangala PS, Bengaluru',
                            prefixIcon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Blood Group'),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _bloodGroup,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                items: _bloodGroups.map((bg) {
                                  return DropdownMenuItem(
                                    value: bg,
                                    child: Text(bg.isEmpty ? 'Select' : bg),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _bloodGroup = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Preferred Emergency Helpline'),
                Row(
                  children: [
                    _buildHelplinePill('112', '112 Unified Emergency'),
                    const SizedBox(width: 6),
                    _buildHelplinePill('1091', '1091 Women Helpline'),
                    const SizedBox(width: 6),
                    _buildHelplinePill('100', '100 Police Control'),
                  ],
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Emergency Medical Notes / Allergies (Optional)'),
                _buildTextInput(
                  controller: _medicalNotesController,
                  hintText: 'e.g. Asthmatic, carries inhaler / Penicillin allergy',
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Secret Covert Duress Safe-Word'),
                _buildTextInput(
                  controller: _safeWordController,
                  hintText: 'help me nexa',
                  prefixIcon: Icons.mic_none,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Speaking or whispering this secret phrase triggers silent SOS broadcasts.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),

                // Consent Checkbox
                InkWell(
                  onTap: () => setState(() => _policeConsent = !_policeConsent),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _policeConsent,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (val) => setState(() => _policeConsent = val ?? true),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'I authorize Nexa Sentinel to dispatch live GPS coordinates and distress telemetry to emergency responders (112/PCR) during confirmed distress triggers.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildGradientButton(
                        text: 'Activate Complete Safety Shield 🛡️',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submitRegistration,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF7C3AED), size: 19)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildHelplinePill(String num, String label) {
    final isSelected = _preferredHelpline == num;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _preferredHelpline = num),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                num,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.replaceAll('$num ', ''),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (icon != null && !isLoading) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
