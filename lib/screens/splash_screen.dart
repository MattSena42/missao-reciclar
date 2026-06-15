import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'menu_screen.dart';
import '../theme/app_text.dart';
import '../theme/app_colors.dart';

/// =====================================================================
/// TELA DE ABERTURA (Splash Screen)
/// Primeira tela exibida ao abrir o aplicativo. Apresenta a identidade
/// visual (logo e plano de fundo) e aguarda uma interação do usuário
/// (toque) para avançar ao menu principal.
/// =====================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// A classe utiliza o [SingleTickerProviderStateMixin] para sincronizar
/// a taxa de atualização da animação com a taxa de quadros da tela do dispositivo.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controlador responsável pelo tempo e repetição da animação
  late AnimationController _controller;

  // Define os valores de início e fim (opacidade) da animação
  late Animation<double> _animation;

  /// -------------------------------------------------------------------
  /// INICIALIZAÇÃO DA ANIMAÇÃO
  /// -------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    // Configura o controlador para uma duração de 800 milissegundos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Configura a transição de opacidade (de 30% até 100% visível)
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    // Inicia a animação em um ciclo infinito de vai e vem (pulsante)
    _controller.repeat(reverse: true);
  }

  /// -------------------------------------------------------------------
  /// LIBERAÇÃO DE MEMÓRIA
  /// -------------------------------------------------------------------
  @override
  void dispose() {
    // É obrigatório descartar o AnimationController quando a tela é
    // fechada para evitar vazamentos de memória e travamentos.
    _controller.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------
  /// NAVEGAÇÃO COM FEEDBACK SONORO
  /// -------------------------------------------------------------------
  Future<void> _goToMenu() async {
    // 1. Toca o som de feedback imediatamente ao toque
    FlameAudio.play('plim.wav');

    // 2. Aguarda um curto período (600ms) para o som ser processado
    // e o usuário sentir o feedback antes da troca de tela.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // 3. Executa a navegação para o Menu
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }

  /// -------------------------------------------------------------------
  /// CONSTRUÇÃO DA INTERFACE (UI)
  /// -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // HitTestBehavior.opaque garante que o toque seja registrado em
        // qualquer lugar da tela, mesmo nas áreas vazias.
        behavior: HitTestBehavior.opaque,
        onTap: _goToMenu, // Agora chama a função assíncrona com áudio

        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg_splash.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 300),
                const SizedBox(height: 40),

                /// =====================================================
                /// TEXTO ANIMADO
                /// Aplica o efeito pulsante (Fade) ao texto instrucional
                /// =====================================================
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    "Toque para iniciar",
                    style: AppText.title.copyWith(
                      fontSize: 30,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
