import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import '../game/missao_reciclar.dart';
import 'game_over_screen.dart';
import '../theme/app_colors.dart';

/// =====================================================================
/// TELA DO JOGO
/// Responsável por hospedar o motor gráfico do jogo (Flame Engine).
/// =====================================================================

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MissaoReciclar _game;

  @override
  void initState() {
    super.initState();

    // Para a música do menu assim que a tela do jogo iniciar
    FlameAudio.bgm.stop();

    _game = MissaoReciclar(
      onGameOver: (int finalScore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameOverScreen(score: finalScore),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Evita flashes brancos na transição
      body: GameWidget.controlled(
        gameFactory: () => _game,
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      ),
    );
  }
}
