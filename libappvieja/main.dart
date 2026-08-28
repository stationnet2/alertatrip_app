import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';
import 'screens/search_flights_screen.dart';
import 'screens/auth_screen.dart';
import 'services/alert_service.dart';
import 'data/city_airports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _initBackgroundTasks();
  runApp(const VuelosApp());
}

void _initBackgroundTasks() async {
  // Ya no hacemos signInAnonymously — el usuario debe loguearse con email/password
  try {
    await AlertService().setupNotifications().timeout(const Duration(seconds: 10));
  } catch (e) {
    print('No se pudieron configurar las notificaciones: $e');
  }

  try {
    await refreshDestinationsFromFirestore().timeout(const Duration(seconds: 10));
  } catch (e) {
    print('No se pudo actualizar el catálogo de destinos: $e');
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
    return MaterialApp(
      title: 'AlertaTrip',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
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
  }
}

/// AuthGate: muestra login si no hay usuario, o la app si está logueado.
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
        if (user == null) {
          return const AuthScreen();
        }
        return const ConnectivityGate(child: SearchFlightsScreen());
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
                    'Sin conexión a internet. Algunas funciones no van a estar disponibles.',
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
