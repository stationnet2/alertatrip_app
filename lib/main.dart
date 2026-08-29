import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/alert_service.dart';
import 'data/city_airports.dart';

final localeNotifier = ValueNotifier<Locale>(const Locale('es'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _initBackgroundTasks();
  runApp(const VuelosApp());
}

void _initBackgroundTasks() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await AlertService().setupNotifications().timeout(const Duration(seconds: 10));
    } catch (e) {
      print('No se pudieron configurar las notificaciones: $e');
    }
  }

  try {
    await refreshDestinationsFromFirestore().timeout(const Duration(seconds: 10));
  } catch (e) {
    print('No se pudo actualizar el catalogo de destinos: $e');
  }

  try {
    await refreshPopularDestinationsFromFirestore().timeout(const Duration(seconds: 10));
  } catch (e) {
    print('No se pudieron actualizar los destinos populares: $e');
  }
}

class VuelosApp extends StatelessWidget {
  const VuelosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          key: ValueKey(locale.languageCode),
          title: 'AlertaTrip',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF0F9D8D),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null && !user.emailVerified) {
          return VerifyEmailScreen(
            onLogout: () async => await FirebaseAuth.instance.signOut(),
          );
        }
        return const ConnectivityGate(child: HomeScreen());
      },
    );
  }
}

class ConnectivityGate extends StatelessWidget {
  final Widget child;
  const ConnectivityGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final offline = snapshot.hasData &&
            snapshot.data!.every((r) => r == ConnectivityResult.none);
        return Column(
          children: [
            if (offline)
              Container(
                width: double.infinity,
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const SafeArea(
                  bottom: false,
                  child: Text(
                    'Sin conexion a internet. Algunas funciones no van a estar disponibles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}