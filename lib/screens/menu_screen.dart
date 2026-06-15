import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flame_audio/flame_audio.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'tutorial_screen.dart';
import '../database/db_helper.dart';
import '../theme/app_buttons.dart';
import '../theme/app_colors.dart';

/// =====================================================================
/// TELA PRINCIPAL
/// Central de navegação do aplicativo. Gerencia o roteamento para as
/// demais telas, executa a verificação de atualizações remotas (OTA)
/// e implementa lógicas de áudio e UX.
/// =====================================================================

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// -------------------------------------------------------------------
  /// CONTROLE DE VERSÃO
  /// -------------------------------------------------------------------
  final String versaoDesteApp = "1.0.2";

  @override
  void initState() {
    super.initState();

    _verificarAtualizacao();

    // Inicia a música de fundo do menu
    FlameAudio.bgm.play('musica_menu.wav');
  }

  /// -------------------------------------------------------------------
  /// VERIFICAÇÃO DE ATUALIZAÇÃO
  /// Consulta o Supabase para checar se há um APK mais recente disponível.
  /// -------------------------------------------------------------------
  Future<void> _verificarAtualizacao() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('app_config').select().single();

      String versaoNuvem = response['versao_atual'];
      String linkDownload = response['link_download'];

      int valorNuvem = int.parse(versaoNuvem.replaceAll('.', ''));
      int valorApp = int.parse(versaoDesteApp.replaceAll('.', ''));

      if (valorNuvem > valorApp && mounted) {
        _mostrarAlertaAtualizacao(versaoNuvem, linkDownload);
      }
    } catch (e) {
      debugPrint("Erro ao checar atualização: $e");
    }
  }

  void _mostrarAlertaAtualizacao(String novaVersao, String link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.lightBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Atualização Disponível!",
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "A versão $novaVersao do Missão Reciclar já está disponível. Baixe agora para ter acesso às novidades!",
            style: const TextStyle(color: AppColors.darkBlue, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Mais tarde",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: AppButtons.primary,
              onPressed: () async {
                final Uri url = Uri.parse(link);
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('Não foi possível abrir o link de atualização');
                }
              },
              child: const Text("Atualizar Agora"),
            ),
          ],
        );
      },
    );
  }

  /// -------------------------------------------------------------------
  /// LÓGICAS DE NAVEGAÇÃO
  /// -------------------------------------------------------------------
  void _startGame(BuildContext context) async {
    final result = await DBHelper.getScores();
    if (!context.mounted) return;

    if (result.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TutorialScreen(irParaOJogo: true),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  void _openRanking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }

  void _openTutorial(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TutorialScreen(irParaOJogo: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_menu.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 200),
              const SizedBox(height: 60),

              ElevatedButton(
                style: AppButtons.primary,
                onPressed: () => _startGame(context),
                child: const Text("Jogar"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: AppButtons.secondary,
                onPressed: () => _openRanking(context),
                child: const Text("Ranking"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: AppButtons.primary,
                onPressed: () => _openTutorial(context),
                child: const Text("Tutorial"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
