import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:missao_reciclar/theme/app_colors.dart';
import 'package:missao_reciclar/theme/app_text.dart';
import '../database/db_helper.dart';

/// =====================================================================
/// TELA DE RANKING
/// Exibe as melhores pontuações dos jogadores. Possui duas abas:
/// - Local (Offline): Pontuações salvas apenas no aparelho do usuário via SQLite.
/// - Mundial (Online): Pontuações globais do servidor Supabase, executando
///   também a sincronização de pontos locais pendentes antes de baixar a lista.
/// =====================================================================

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // Controle de estado para a aba selecionada (true = Local / false = Mundial)
  bool mostrarLocal = true;

  // Controle de estado para a exibição do ícone de carregamento
  bool _isLoading = false;

  // Lista dinâmica que armazenará os dados da tabela, independente de
  // virem do SQLite local ou do Supabase na nuvem.
  List<Map<String, dynamic>> _scores = [];

  // Instância única de conexão com o backend em nuvem
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Ao abrir a tela, carrega imediatamente o ranking local por padrão
    _carregarScores();
  }

  /// -------------------------------------------------------------------
  /// LÓGICA DE CARREGAMENTO E SINCRONIZAÇÃO DE DADOS
  /// -------------------------------------------------------------------
  Future<void> _carregarScores() async {
    setState(() => _isLoading = true);

    if (mostrarLocal) {
      /// ===============================================================
      /// CARREGAMENTO LOCAL (SQLite)
      /// ===============================================================
      final dados = await DBHelper.getScores();
      setState(() {
        _scores = dados;
        _isLoading = false;
      });
    } else {
      /// ===============================================================
      /// CARREGAMENTO MUNDIAL (Supabase) + SINCRONIZAÇÃO
      /// ===============================================================
      try {
        // 1. SINCRONIZAÇÃO: Busca pontos locais que ainda não foram para a nuvem
        final unsynced = await DBHelper.getUnsyncedScores();

        if (unsynced.isNotEmpty) {
          // Prepara a lista de pontos pendentes no formato que o banco online exige
          final recordsToInsert = unsynced
              .map((e) => {'name': e['name'], 'score': e['score']})
              .toList();

          // Envia em lote para a nuvem. O 'upsert' atualiza a pontuação se
          // o jogador (name) já existir, ou insere uma nova linha se for novo.
          await supabase
              .from('ranking_v2')
              .upsert(recordsToInsert, onConflict: 'name');

          // Marca os registros locais como "sincronizados" (status 1) para
          // não enviá-los novamente na próxima vez.
          List<int> syncedIds = unsynced.map((e) => e['id'] as int).toList();
          await DBHelper.markAsSynced(syncedIds);
        }

        // 2. DOWNLOAD DO RANKING MUNDIAL: Pega o Top 50 geral atualizado
        final response = await supabase
            .from('ranking_v2')
            .select('name, score')
            .order(
              'score',
              ascending: false,
            ) // Ordem decrescente (maior pro menor)
            .limit(50);

        // Atualiza a lista na tela com os dados vindos do servidor
        setState(() {
          _scores = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      } catch (e) {
        // Em caso de falha (sem internet ou servidor fora do ar), para o
        // carregamento e exibe um alerta (SnackBar) na base da tela.
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro ao conectar com o ranking mundial. Verifique sua internet!',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  /// -------------------------------------------------------------------
  /// ALTERNÂNCIA DE ABAS
  /// -------------------------------------------------------------------
  void _mudarAba(bool paraLocal) {
    // Evita recarregar se o usuário clicar na aba que já está aberta
    if (mostrarLocal == paraLocal) return;

    setState(() {
      mostrarLocal = paraLocal;
    });
    // Dispara a busca de dados correspondente à nova aba selecionada
    _carregarScores();
  }

  /// -------------------------------------------------------------------
  /// COLORAÇÃO CONDICIONAL DO PÓDIO
  /// Retorna as cores de Ouro, Prata e Bronze para os 3 primeiros colocados.
  /// Retorna a cor padrão (Azul Claro) para o restante da lista.
  /// -------------------------------------------------------------------
  Color _getPodiumColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Ouro
      case 1:
        return const Color(0xFFC0C0C0); // Prata
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.lightBlue; // Padrão
    }
  }

  /// -------------------------------------------------------------------
  /// CONSTRUÇÃO DA INTERFACE (UI)
  /// -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        elevation: 0,
        // BOTÃO DE VOLTAR CUSTOMIZADO
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.orange, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Voltar ao Menu',
        ),
        title: Text(
          "Ranking",
          style: AppText.title.copyWith(color: AppColors.orange, fontSize: 28),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// ===========================================================
          /// SELETOR DE ABAS
          /// ===========================================================
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.blueGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                // Aba Local
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _mudarAba(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: mostrarLocal
                            ? AppColors.orange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Local",
                        style: TextStyle(
                          fontFamily: 'Archive',
                          fontSize: 18,
                          color: mostrarLocal
                              ? Colors.white
                              : AppColors.lightBlue,
                        ),
                      ),
                    ),
                  ),
                ),

                // Aba Mundial
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _mudarAba(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: !mostrarLocal
                            ? AppColors.orange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Mundial",
                        style: TextStyle(
                          fontFamily: 'Archive',
                          fontSize: 18,
                          color: !mostrarLocal
                              ? Colors.white
                              : AppColors.lightBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ===========================================================
          /// ÁREA DA LISTA
          /// ===========================================================
          Expanded(
            child: Container(
              width: double.infinity,
              // clipBehavior IMPEDE QUE A LISTA Vaze PELAS BORDAS ARREDONDADAS
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: AppColors.blueGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _isLoading
                  // Exibe carregamento enquanto busca os dados
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    )
                  : _scores.isEmpty
                  // Exibe mensagem caso o banco selecionado esteja vazio
                  ? const Center(
                      child: Text(
                        "Nenhuma pontuação disponível",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.darkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  // Renderiza a lista de cartões (Cards)
                  : ListView.builder(
                      itemCount: _scores.length,
                      // AUMENTO DO ESPAÇAMENTO INFERIOR (bottom: 40) PARA NÃO CORTAR O ÚLTIMO ITEM
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 12,
                        right: 12,
                        bottom: 40,
                      ),
                      itemBuilder: (context, index) {
                        final item = _scores[index];
                        final cardColor = _getPodiumColor(index);

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.darkBlue,
                              child: CircleAvatar(
                                backgroundColor: AppColors.orange,
                                radius: 22,
                                child: Text(
                                  "${index + 1}º",
                                  style: const TextStyle(
                                    color: AppColors.lightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              item['name'] ?? 'Sem nome',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                border: Border.all(
                                  color: AppColors.darkBlue,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${item['score']} pts",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
