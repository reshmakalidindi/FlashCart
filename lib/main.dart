import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gracefully initialize Firebase core with demo options for Web/Desktop
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDemoFlashCartMockApiKey12345678',
          appId: '1:123456789012:web:abcdef12345678',
          messagingSenderId: '123456789012',
          projectId: 'flashcart-prototype',
          storageBucket: 'flashcart-prototype.appspot.com',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized successfully!');
  } catch (e) {
    debugPrint('Firebase initialization warning (running in Demo/Offline mode): $e');
  }

  runApp(const FlashCartApp());
}

class FlashCartApp extends StatelessWidget {
  const FlashCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'FlashCart - Scan. Shop. Pay. Go.',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
