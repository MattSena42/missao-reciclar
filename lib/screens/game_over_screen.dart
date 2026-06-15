import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'menu_screen.dart';
import 'game_screen.dart';
import '../database/db_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_buttons.dart';

/// =====================================================================
/// TELA DE GAME OVER
/// Exibe a pontuação final do jogador, apresenta uma curiosidade
/// ambiental aleatória e coleta o nome do usuário para registro no
/// ranking local e global.
/// =====================================================================

class GameOverScreen extends StatefulWidget {
  final int score;

  const GameOverScreen({super.key, required this.score});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  // Controlador responsável por capturar o texto digitado pelo usuário.
  final TextEditingController _nomeController = TextEditingController();

  /// -------------------------------------------------------------------
  /// VARIÁVEIS DE ESTADO
  /// -------------------------------------------------------------------

  // Gera dinamicamente a lista com os caminhos das imagens de curiosidades.
  final List<String> _curiosidades = List.generate(
    16,
    (index) => 'assets/images/curiosidades/curiosidade${index + 1}.png',
  );

  // Variável estática (mantida em memória durante a execução do app) para
  // lembrar o nome do jogador e evitar digitações repetidas a cada partida.
  static String? ultimoNome;

  // Armazena a imagem selecionada para a partida atual.
  late String curiosidadeEscolhida;

  @override
  void initState() {
    super.initState();

    // Toca o som de derrota assim que a tela abrir
    FlameAudio.play('derrota.wav');

    // Preenche o campo de texto automaticamente se o jogador já tiver
    // digitado um nome em uma partida anterior.
    if (ultimoNome != null) {
      _nomeController.text = ultimoNome!;
    }

    // Sorteia uma curiosidade aleatória para exibição.
    curiosidadeEscolhida =
        _curiosidades[Random().nextInt(_curiosidades.length)];
  }

  @override
  void dispose() {
    // Libera os recursos do controlador de texto para evitar vazamento de memória.
    _nomeController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------
  /// MÉTODOS DE AÇÃO
  /// -------------------------------------------------------------------

  // Processa o nome digitado e salva a pontuação no banco de dados local (SQLite).
  Future<void> _salvarPontuacao() async {
    // POLIMENTO UX: Recolhe o teclado virtual suavemente antes de trocar de tela
    FocusManager.instance.primaryFocus?.unfocus();

    String textoDigitado = _nomeController.text.trim().toUpperCase();

    // Aplica um nome padrão caso o usuário deixe o campo em branco.
    String nome = textoDigitado.isEmpty ? "JOGADOR ANÔNIMO" : textoDigitado;

    // Atualiza a variável estática para a próxima partida.
    ultimoNome = textoDigitado.isNotEmpty ? textoDigitado : null;

    // Registra no banco apenas se não for anônimo (evita poluir o ranking).
    if (nome != "JOGADOR ANÔNIMO") {
      await DBHelper.insertScore(nome, widget.score);
    }
  }

  // Salva a pontuação e reinicia a partida imediatamente.
  void _jogarNovamente() async {
    await _salvarPontuacao();

    // O 'mounted' garante que a tela ainda existe antes de tentar navegar,
    // prevenindo erros caso o usuário saia do app durante o salvamento.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  // Salva a pontuação e retorna à tela inicial.
  void _voltarMenu() async {
    await _salvarPontuacao();

    if (mounted) {
      // pushAndRemoveUntil limpa o histórico de navegação, impedindo que o
      // botão de voltar do celular retorne para a tela de Game Over.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
        (route) => false,
      );
    }
  }

  /// -------------------------------------------------------------------
  /// CONSTRUÇÃO DA INTERFACE (UI)
  /// -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Center(
        // SingleChildScrollView previne o erro de tela esmagada (Overflow)
        // quando o teclado virtual do celular é aberto.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          // ConstrainedBox limita a largura máxima do cartão, garantindo que
          // a interface não fique deformada caso seja executada em tablets.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppColors.lightBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Fim do Jogo',
                      style: AppText.title.copyWith(color: AppColors.orange),
                    ),
                    const SizedBox(height: 16),

                    /// -------------------------------------------------
                    /// IMAGEM DA CURIOSIDADE
                    /// -------------------------------------------------
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.darkBlue,
                            width: 5.0,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(
                          curiosidadeEscolhida,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// -------------------------------------------------
                    /// PONTUAÇÃO ALCANÇADA
                    /// -------------------------------------------------
                    Text(
                      'Sua pontuação: ${widget.score}',
                      style: AppText.body.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// -------------------------------------------------
                    /// CAMPO DE NOME (TextField)
                    /// -------------------------------------------------
                    TextField(
                      controller: _nomeController,
                      // Força letras maiúsculas para padronizar o ranking
                      textCapitalization: TextCapitalization.characters,
                      style: AppText.body.copyWith(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        labelText: 'Digite seu nome',
                        labelStyle: AppText.body.copyWith(
                          color: AppColors.darkBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: AppColors.orange,
                            width: 2.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: AppColors.darkBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// -------------------------------------------------
                    /// BOTÕES DE AÇÃO
                    /// -------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _jogarNovamente,
                            style: AppButtons.primary,
                            child: const Text('Reiniciar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _voltarMenu,
                            style: AppButtons.secondary,
                            child: const Text('Início'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
