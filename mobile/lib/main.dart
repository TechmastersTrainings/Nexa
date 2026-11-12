import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/voice_trigger_provider.dart';
import 'providers/incident_provider.dart';
import 'core/constants.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.init();
  runApp(const NexaSafetyApp());
}

class NexaSafetyApp extends StatelessWidget {
  const NexaSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuth()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, IncidentProvider, VoiceTriggerProvider>(
          create: (_) => VoiceTriggerProvider(),
          update: (_, auth, incident, voice) {
            final v = voice ?? VoiceTriggerProvider();
            v.syncCustomSafeWord(auth.user?.safeWordPhrase);
            v.attachDistressCallback((event) async {
              await incident.triggerEmergency(
                token: auth.token,
                user: auth.user,
                triggerType: 'voice_trigger_${event.matchedPhrase}',
                // Voice trigger already opens GSM call immediately; trigger SMS fallback only if no server connection
                triggerGsmFallbackIfOffline: false,
              );
            });
            return v;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Nexa AI Safety',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED),
            secondary: Color(0xFF4F46E5),
            surface: Colors.white,
            error: Color(0xFFEF4444),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8FAFC),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.initial || (auth.status == AuthStatus.loading && auth.user == null)) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Starting Nexa Security Engine...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
