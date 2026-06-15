import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';
import '../theme/app_buttons.dart';
import 'game_screen.dart';

/// =====================================================================
/// TELA DE TUTORIAL
/// Exibe as instruções do jogo em formato de vídeos curtos.
/// Pode ser acessada de duas formas:
/// 1. Pelo primeiro uso do app (onde o botão final direciona para o Jogo).
/// 2. Pelo menu principal (onde o botão final apenas retorna ao Menu).
/// =====================================================================

class TutorialScreen extends StatefulWidget {
  // Parâmetro que define o comportamento do botão final ("JOGAR!" ou "ENTENDI")
  final bool irParaOJogo;

  const TutorialScreen({super.key, required this.irParaOJogo});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  // Controlador responsável pela transição deslizante entre as páginas
  final PageController _pageController = PageController();

  // Mantém o estado da página atual para atualizar os indicadores (bolinhas) na UI
  int _paginaAtual = 0;

  /// -------------------------------------------------------------------
  /// FONTE DE DADOS (Vídeos)
  /// Caminhos para os arquivos locais de vídeo.
  /// -------------------------------------------------------------------
  final List<String> _videosTutorial = [
    'assets/videos/tut_1.mp4',
    'assets/videos/tut_2.mp4',
    'assets/videos/tut_3.mp4',
    'assets/videos/tut_4.mp4',
    'assets/videos/tut_5.mp4',
    'assets/videos/tut_6.mp4',
    'assets/videos/tut_7.mp4',
    'assets/videos/tut_8.mp4',
    'assets/videos/tut_9.mp4',
    'assets/videos/tut_10.mp4',
    'assets/videos/tut_11.mp4',
    'assets/videos/tut_12.mp4',
  ];

  /// -------------------------------------------------------------------
  /// MÉTODOS DE CONTROLE DO CARROSSEL
  /// -------------------------------------------------------------------
  void _proximaPagina() {
    // Se não for a última página, avança para o próximo vídeo com uma animação
    if (_paginaAtual < _videosTutorial.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Se for a última página, executa a ação final do tutorial
      _finalizarTutorial();
    }
  }

  void _finalizarTutorial() {
    // Roteamento dinâmico com base no parâmetro recebido na criação da tela
    if (widget.irParaOJogo) {
      // Substitui o histórico de navegação para iniciar a partida
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    } else {
      // Apenas volta para a tela anterior (o Menu)
      Navigator.pop(context);
    }
  }

  /// -------------------------------------------------------------------
  /// CONSTRUÇÃO DA INTERFACE (UI)
  /// -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      // Stack é utilizado para sobrepor o botão de "Pular" (X) em cima do vídeo
      body: Stack(
        children: [
          Column(
            children: [
              /// =======================================================
              /// ÁREA DE VISUALIZAÇÃO DOS VÍDEOS (PageView)
              /// =======================================================
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _videosTutorial.length,
                  // Atualiza o estado da página atual ao deslizar com o dedo
                  onPageChanged: (index) {
                    setState(() {
                      _paginaAtual = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    // Instancia um widget separado para cada vídeo para garantir
                    // o gerenciamento correto da memória e dos controladores.
                    return VideoSlideWidget(videoPath: _videosTutorial[index]);
                  },
                ),
              ),

              /// =======================================================
              /// RODAPÉ
              /// =======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 15, bottom: 40),
                decoration: const BoxDecoration(color: AppColors.darkBlue),
                child: Column(
                  children: [
                    // Indicadores de Progresso (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _videosTutorial.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          // Estica o indicador ativo para virar um retângulo
                          width: _paginaAtual == index ? 20 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _paginaAtual == index
                                ? AppColors.orange
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botão de Avançar Dinâmico
                    ElevatedButton(
                      style: AppButtons.primary,
                      onPressed: _proximaPagina,
                      child: Text(
                        // Altera o texto do botão se for a última página
                        _paginaAtual == _videosTutorial.length - 1
                            ? (widget.irParaOJogo ? 'JOGAR!' : 'ENTENDI')
                            : 'PRÓXIMO',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// ===========================================================
          /// BOTÃO DE PULAR TUTORIAL
          /// ===========================================================
          Positioned(
            top: 15,
            right: 15,
            // SafeArea adicionado para garantir que o botão "X" nunca fique
            // escondido debaixo do Notch da câmera em modo imersivo
            child: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.orange, // Fundo Laranja Sólido
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.darkBlue,
                    size: 28,
                  ), // Ícone Azul Escuro
                  onPressed: _finalizarTutorial,
                  tooltip: 'Pular Tutorial',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================================================
/// WIDGET DE RENDERIZAÇÃO DE VÍDEO ISOLADO
/// Componente criado para encapsular a lógica de reprodução de um único vídeo.
/// Ao separar a lógica em um StatefulWidget próprio, evitamos o carregamento
/// simultâneo de todos os vídeos na memória, garantindo alta performance.
/// =====================================================================

class VideoSlideWidget extends StatefulWidget {
  final String videoPath;

  const VideoSlideWidget({super.key, required this.videoPath});

  @override
  State<VideoSlideWidget> createState() => _VideoSlideWidgetState();
}

class _VideoSlideWidgetState extends State<VideoSlideWidget> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  /// -------------------------------------------------------------------
  /// CARREGAMENTO DO VÍDEO
  /// -------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.asset(
            widget.videoPath,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..setVolume(0.0)
          ..setLooping(false) // O vídeo não deve repetir automaticamente
          ..initialize().then((_) {
            // Ao terminar de carregar o arquivo na memória, atualiza a tela
            // e inicia a reprodução imediatamente
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _controller.play();
            }
          });
  }

  /// -------------------------------------------------------------------
  /// LIBERAÇÃO DE MEMÓRIA
  /// -------------------------------------------------------------------
  @override
  void dispose() {
    // Descarrega o vídeo da memória assim que o usuário muda para a próxima página
    _controller.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------
  /// CONSTRUÇÃO DO PLAYER
  /// -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.darkBlue,
      child: Center(
        child: _isVideoInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: AppColors.orange),
      ),
    );
  }
}
