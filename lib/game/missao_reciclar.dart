import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// =====================================================================
/// NÚCLEO DO JOGO (Flame Engine)
/// Classe principal que estende [FlameGame]. Gerencia o loop de atualização
/// (Game Loop), a renderização gráfica, inputs do usuário e a física do jogo.
/// Utiliza Mixins para capturar toques na tela e monitorar o ciclo de vida do app.
/// =====================================================================

class MissaoReciclar extends FlameGame
    with TapCallbacks, WidgetsBindingObserver {
  // Callback executado quando o jogador erra a lixeira, enviando a pontuação
  // final de volta para a camada do Flutter (GameScreen -> GameOverScreen).
  final void Function(int finalScore) onGameOver;

  MissaoReciclar({required this.onGameOver});

  /// -------------------------------------------------------------------
  /// CONFIGURAÇÕES GERAIS E SISTEMA DE GRADE (Grid)
  /// -------------------------------------------------------------------
  static const int gridColumns = 5;
  static const int gridRows = 10;
  static const double topPadding = 50.0;

  // Matriz que divide a tela em células mapeadas para movimentação precisa
  late List<List<Rect>> grid;

  /// -------------------------------------------------------------------
  /// ESTADO DO JOGO
  /// -------------------------------------------------------------------
  Lixo? lixoAtual;
  double tempoAcumulado = 0;
  int linhaAtual = 0;
  int colunaAtual = 0;
  int pontuacao = 0;
  double quedaIntervalo = 0.5; // Velocidade inicial (segundos por linha)

  final Random random = Random();

  /// -------------------------------------------------------------------
  /// RENDERIZAÇÃO E CACHE DE ASSETS
  /// -------------------------------------------------------------------
  late TextPainter textPainter;
  late TextStyle textStyle;

  final Map<String, Sprite> spritesCache = {};
  Sprite? backgroundSprite;
  late List<LixeiraComponent> lixeirasComponentes;

  int currentBgId = 1;
  int currentBgVariant = 1;

  /// -------------------------------------------------------------------
  /// ÁUDIO
  /// -------------------------------------------------------------------
  AudioPlayer? _sfxPlayer;

  // Dicionário de mapeamento entre cores, tipos de lixo e identificadores
  final List<Color> lixeiraColors = [
    Colors.blue, // Papel
    Colors.red, // Plástico
    Colors.green, // Vidro
    Colors.yellow, // Metal
    Colors.brown, // Orgânico
  ];

  final Map<Color, int> corParaId = {
    Colors.blue: 1,
    Colors.red: 2,
    Colors.green: 3,
    Colors.yellow: 4,
    Colors.brown: 5,
  };

  /// -------------------------------------------------------------------
  /// INICIALIZAÇÃO DO JOGO (Carregamento de Recursos)
  /// -------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Configuração do Texto do Placar
    textStyle = AppText.title.copyWith(fontSize: 26, color: AppColors.darkBlue);
    textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // 2. Cálculo dinâmico da Grade (Grid) com base no tamanho da tela do dispositivo
    grid = List.generate(
      gridRows,
      (row) => List.generate(gridColumns, (col) {
        double cellWidth = size.x / gridColumns;
        double cellHeight = (size.y - topPadding) / gridRows;
        return Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight + topPadding,
          cellWidth,
          cellHeight,
        );
      }),
    );

    // 3. Pré-carregamento de Sprites (Lixos) para evitar travamentos
    for (int id = 1; id <= 5; id++) {
      for (int variante = 1; variante <= 3; variante++) {
        spritesCache['lixo_${id}_${variante}_cor'] = await loadSprite(
          'lixo_${id}_${variante}_cor.png',
        );
        spritesCache['lixo_${id}_${variante}_semcor'] = await loadSprite(
          'lixo_${id}_${variante}_semcor.png',
        );
      }
    }

    // 4. Posicionamento das Lixeiras na última linha da grade
    lixeirasComponentes = [];
    for (int col = 0; col < gridColumns; col++) {
      int idLixeira = corParaId[lixeiraColors[col]]!;
      final sprite = await loadSprite('lixeira_$idLixeira.png');
      spritesCache['lixeira_$idLixeira'] = sprite;

      final cell = grid[gridRows - 1][col];
      final lixeiraComp = LixeiraComponent(
        id: idLixeira,
        sprite: sprite,
        gridPosition: cell,
      );
      lixeirasComponentes.add(lixeiraComp);
      add(lixeiraComp);
    }

    // 5. Configuração do Cenário de Fundo (Background)
    currentBgId = random.nextInt(7) + 1;
    currentBgVariant = 1;
    for (int i = 1; i <= 3; i++) {
      spritesCache['bg_${currentBgId}_$i'] = await loadSprite(
        'bg_${currentBgId}_$i.png',
      );
    }
    backgroundSprite = spritesCache['bg_${currentBgId}_1'];

    // 6. Configuração e Pré-carregamento de Áudios
    await FlameAudio.audioCache.loadAll([
      'papel.wav',
      'plastico.wav',
      'vidro.wav',
      'metal.wav',
      'organico.wav',
    ]);
    _sfxPlayer = AudioPlayer();
    await _sfxPlayer!.setReleaseMode(ReleaseMode.stop);

    await FlameAudio.bgm.stop();
    await FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('musica_game.wav', volume: 0.3);

    // Inicia a partida gerando o primeiro item
    spawnNovoLixo();

    // Registra o motor para escutar eventos do sistema operacional
    WidgetsBinding.instance.addObserver(this);
  }

  /// -------------------------------------------------------------------
  /// DESCARTE E LIMPEZA DE MEMÓRIA (Lifecycle)
  /// -------------------------------------------------------------------
  @override
  void onRemove() {
    FlameAudio.bgm.stop();
    _sfxPlayer?.stop();
    _sfxPlayer?.dispose();
    _sfxPlayer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  // Pausa a música caso o usuário minimize o aplicativo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      FlameAudio.bgm.pause();
    } else {
      if (!paused) {
        FlameAudio.bgm.resume();
      }
    }
  }

  /// -------------------------------------------------------------------
  /// CONTROLE DE EFEITOS SONOROS (SFX)
  /// -------------------------------------------------------------------
  void tocarSomLixeira(int idLixeira) {
    String soundFile;
    switch (idLixeira) {
      case 1:
        soundFile = 'papel.wav';
        break;
      case 2:
        soundFile = 'plastico.wav';
        break;
      case 3:
        soundFile = 'vidro.wav';
        break;
      case 4:
        soundFile = 'metal.wav';
        break;
      case 5:
        soundFile = 'organico.wav';
        break;
      default:
        return;
    }

    if (_sfxPlayer != null) {
      final cachedUri = FlameAudio.audioCache.loadedFiles[soundFile];
      if (cachedUri != null) {
        _sfxPlayer!.play(DeviceFileSource(cachedUri.path), volume: 1.0);
      } else {
        _sfxPlayer!.play(AssetSource('audio/$soundFile'), volume: 1.0);
      }
    }
  }

  /// -------------------------------------------------------------------
  /// ENTRADAS DO USUÁRIO (Inputs)
  /// -------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (lixoAtual == null) return;

    double alturaLixeiras = grid[gridRows - 1][0].top;

    // Ação: Hard Drop (Tocar na área das lixeiras derruba o item instantaneamente)
    if (event.localPosition.y >= alturaLixeiras) {
      linhaAtual = gridRows - 2;
      Rect posicaoFinal = grid[linhaAtual][colunaAtual];
      lixoAtual!.moverPara(posicaoFinal);
      lixoAtual!.position.y = posicaoFinal.top;
      tempoAcumulado =
          quedaIntervalo; // Força a verificação de colisão imediata
      return;
    }

    // Ação: Movimento Horizontal (Tocar nos lados da tela)
    int novaColuna = colunaAtual;
    if (event.localPosition.x < size.x / 2 && colunaAtual > 0) {
      novaColuna--; // Move para a esquerda
    } else if (event.localPosition.x >= size.x / 2 &&
        colunaAtual < gridColumns - 1) {
      novaColuna++; // Move para a direita
    }

    if (novaColuna != colunaAtual) {
      colunaAtual = novaColuna;
      double novoX = grid[linhaAtual][colunaAtual].left;
      lixoAtual!.moverHorizontalmente(novoX);
    }
  }

  /// -------------------------------------------------------------------
  /// GERAÇÃO DE ITENS (Spawning)
  /// -------------------------------------------------------------------
  void spawnNovoLixo() {
    linhaAtual = 0;
    colunaAtual = random.nextInt(gridColumns);

    // Acima de 200 pontos, os lixos perdem a cor para aumentar a dificuldade
    bool colorido = pontuacao < 200;
    Color corEscolhida = lixeiraColors[random.nextInt(lixeiraColors.length)];
    int idLixo = corParaId[corEscolhida]!;
    int variante = random.nextInt(3) + 1;

    String spriteKey =
        'lixo_${idLixo}_${variante}_${colorido ? "cor" : "semcor"}';
    Sprite sprite = spritesCache[spriteKey]!;

    lixoAtual = Lixo(
      grid[linhaAtual][colunaAtual],
      Paint()..color = corEscolhida,
      id: idLixo,
      sprite: sprite,
    );
    add(lixoAtual!);
  }

  /// -------------------------------------------------------------------
  /// CURVA DE DIFICULDADE E PROGRESSÃO VISUAL
  /// -------------------------------------------------------------------
  void atualizarVelocidade() {
    if (pontuacao < 100) {
      quedaIntervalo = 0.5;
    } else if (pontuacao < 300) {
      quedaIntervalo = 0.4;
    } else if (pontuacao < 400) {
      quedaIntervalo = 0.3;
    } else if (pontuacao < 500) {
      quedaIntervalo = 0.2;
    } else if (pontuacao < 1000) {
      quedaIntervalo = 0.15;
    } else {
      quedaIntervalo = 0.1;
    } // Velocidade Máxima
  }

  void atualizarFundo() {
    // Evolui a complexidade do plano de fundo de acordo com a pontuação
    if (pontuacao >= 500 && currentBgVariant != 3) {
      currentBgVariant = 3;
      backgroundSprite = spritesCache['bg_${currentBgId}_3'];
    } else if (pontuacao >= 200 && pontuacao < 500 && currentBgVariant != 2) {
      currentBgVariant = 2;
      backgroundSprite = spritesCache['bg_${currentBgId}_2'];
    }
  }

  /// -------------------------------------------------------------------
  /// LOOP DE ATUALIZAÇÃO DO JOGO (Game Loop Principal)
  /// Executado dezenas de vezes por segundo.
  /// -------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);
    atualizarVelocidade();
    atualizarFundo();

    if (lixoAtual != null) {
      tempoAcumulado += dt;

      // Controla a gravidade/queda do item
      if (tempoAcumulado >= quedaIntervalo) {
        tempoAcumulado = 0;

        // Se ainda não chegou na lixeira, continua caindo
        if (linhaAtual < gridRows - 2) {
          linhaAtual++;
          lixoAtual!.moverPara(grid[linhaAtual][colunaAtual]);
        }
        // Se chegou no fundo, processa a colisão/validação
        else {
          int idLixo = lixoAtual!.id;
          int idLixeira = corParaId[lixeiraColors[colunaAtual]]!;

          final lixoParaRemover = lixoAtual;
          lixoAtual = null;
          lixoParaRemover?.removeFromParent();

          // Lógica de Acerto (Match)
          if (idLixo == idLixeira) {
            pontuacao += 10;

            // Efeitos visuais e sonoros de acerto
            final lixeiraCell = grid[gridRows - 2][colunaAtual];
            adicionarEfeitoEstrelas(lixeiraCell.center);
            tocarSomLixeira(idLixeira);

            // Animação da lixeira
            final lixeiraAlvo = lixeirasComponentes[colunaAtual];
            lixeiraAlvo.removeAll(lixeiraAlvo.children.whereType<Effect>());
            lixeiraAlvo.add(
              SequenceEffect([
                RotateEffect.by(
                  10 * (pi / 180),
                  EffectController(duration: 0.08, curve: Curves.easeInOut),
                ),
                RotateEffect.by(
                  -20 * (pi / 180),
                  EffectController(duration: 0.16, curve: Curves.easeInOut),
                ),
                RotateEffect.to(
                  0,
                  EffectController(duration: 0.08, curve: Curves.easeInOut),
                ),
              ]),
            );

            spawnNovoLixo();
          }
          // Lógica de Erro (Game Over)
          else {
            _sfxPlayer?.stop();
            FlameAudio.bgm.stop();
            pauseEngine(); // Congela o motor gráfico

            // Utiliza microtask para garantir que o callback retorne para o Flutter em segurança
            Future.microtask(() => onGameOver(pontuacao));
            return;
          }
        }
      }
    }
  }

  /// -------------------------------------------------------------------
  /// SISTEMA DE PARTÍCULAS
  /// Cria uma explosão de estrelas/partículas ao acertar a lixeira.
  /// -------------------------------------------------------------------
  void adicionarEfeitoEstrelas(Offset posicao) {
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 20,
          lifespan: 0.8,
          generator: (i) => AcceleratedParticle(
            position: posicao.toVector2(),
            speed: (Vector2.random() - Vector2.random()) * 150,
            acceleration: Vector2(0, 200), // Simula gravidade nas partículas
            child: CircleParticle(
              radius: 2 + random.nextDouble() * 2,
              paint: Paint()..color = const Color.fromARGB(204, 255, 93, 40),
            ),
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------
  /// RENDERIZAÇÃO GRÁFICA DIRETA NA CANVAS
  /// -------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    // Renderiza o cenário de fundo
    if (backgroundSprite != null) {
      backgroundSprite!.renderRect(canvas, size.toRect());
    }
    super.render(canvas);

    // Formata o texto do placar
    final String textoPlacar = 'Pontos: $pontuacao';
    textPainter.text = TextSpan(
      text: textoPlacar,
      style: AppText.title.copyWith(fontSize: 26, color: AppColors.lightBlue),
    );
    textPainter.layout();

    final Offset posicaoTexto = Offset(
      (size.x / 2) - (textPainter.width / 2),
      topPadding - 20,
    );

    // Desenha a moldura atrás do texto do placar para melhor contraste
    final Rect moldura = Rect.fromLTWH(
      posicaoTexto.dx - 10,
      posicaoTexto.dy - 5,
      textPainter.width + 20,
      textPainter.height + 10,
    );
    final Paint molduraPaint = Paint()
      ..color = AppColors.darkBlue
      ..style = PaintingStyle.fill;

    canvas.drawRect(moldura, molduraPaint);
    textPainter.paint(canvas, posicaoTexto);
  }
}

/// =====================================================================
/// COMPONENTE: ITEM DE LIXO
/// Representa o objeto que cai pela tela. Possui lógica própria de
/// interpolação (movimento suave) e renderização (sombra artificial).
/// =====================================================================

class Lixo extends SpriteComponent with HasGameReference<MissaoReciclar> {
  int id;
  Paint tinta;
  Vector2 destino; // Coordenada-alvo para movimento suave

  Lixo(Rect posicao, this.tinta, {required this.id, required Sprite sprite})
    : destino = posicao.topLeft.toVector2(),
      super(
        sprite: sprite,
        position: posicao.topLeft.toVector2(),
        size: posicao.size.toVector2(),
      );

  // Define a nova célula alvo na grade
  void moverPara(Rect novaPosicao) {
    destino.y = novaPosicao.top;
    destino.x = novaPosicao.left;
  }

  void moverHorizontalmente(double novoX) {
    destino.x = novoX;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Interpolação Linear (Lerp): Move o sprite em direção ao destino de forma fluida,
    // independente do framerate do dispositivo.
    position.x += (destino.x - position.x) * 15 * dt;
    position.y += (destino.y - position.y) * 15 * dt;
  }

  @override
  void render(Canvas canvas) {
    // Desenha uma sombra estilizada atrás do item para dar profundidade (3D)
    final double offsetX = 4.0;
    final double offsetY = 4.0;
    final double blurSigma = 5.0;
    final Color shadowColor = const Color.fromARGB(130, 0, 0, 0);

    final sombraPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    final sombraRect = Rect.fromLTWH(offsetX, offsetY, size.x, size.y);

    canvas.drawOval(sombraRect, sombraPaint);
    super.render(canvas); // Renderiza o sprite original por cima da sombra
  }
}

/// =====================================================================
/// COMPONENTE: LIXEIRA
/// Elemento estático na base da tela que recebe animações de reação (tremer)
/// quando um item correto é depositado.
/// =====================================================================

class LixeiraComponent extends SpriteComponent {
  int id;

  LixeiraComponent({
    required this.id,
    required Sprite sprite,
    required Rect gridPosition,
  }) : super(
         sprite: sprite,
         position: gridPosition.bottomCenter.toVector2(),
         size: gridPosition.size.toVector2(),
         anchor: Anchor
             .bottomCenter, // Ancorado pela base para facilitar alinhamento
       );
}
