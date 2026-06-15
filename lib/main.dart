import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'theme/app_buttons.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';

/// =====================================================================
/// ARQUIVO PRINCIPAL (Entry Point)
/// Ponto de partida do aplicativo "Missão Reciclar".
/// Responsável por inicializar os serviços essenciais (como o Supabase)
/// e aplicar o Design System (tema global) antes de carregar a primeira tela.
/// =====================================================================

Future<void> main() async {
  /// -------------------------------------------------------------------
  /// PREPARAÇÃO DO MOTOR DO FLUTTER
  /// -------------------------------------------------------------------
  WidgetsFlutterBinding.ensureInitialized();

  /// -------------------------------------------------------------------
  /// CARREGAMENTO DAS VARIÁVEIS DE AMBIENTE
  /// -------------------------------------------------------------------
  await dotenv.load(fileName: ".env");

  /// -------------------------------------------------------------------
  /// CONFIGURAÇÃO DE TELA CHEIA GLOBAL
  /// -------------------------------------------------------------------
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  /// -------------------------------------------------------------------
  /// INICIALIZAÇÃO DO SUPABASE
  /// -------------------------------------------------------------------
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Inicia a renderização da árvore de widgets do aplicativo
  runApp(const MissaoReciclarApp());
}

/// =====================================================================
/// WIDGET RAIZ DO APLICATIVO
/// =====================================================================

class MissaoReciclarApp extends StatelessWidget {
  const MissaoReciclarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Missão Reciclar',
      debugShowCheckedModeBanner: false,

      /// -----------------------------------------------------------------
      /// APLICAÇÃO DO DESIGN SYSTEM GLOBAL
      /// -----------------------------------------------------------------
      theme: ThemeData(
        fontFamily: 'Archive',
        primaryColor: AppColors.orange,
        scaffoldBackgroundColor: AppColors.lightBlue,

        textTheme: const TextTheme(
          bodyLarge: AppText.body,
          bodyMedium: AppText.body,
          titleLarge: AppText.title,
          labelLarge: AppText.button,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
      ),

      home: const SplashScreen(),
    );
  }
}
