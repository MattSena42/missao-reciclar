import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// =====================================================================
/// CLASSE DBHelper
/// Responsável por gerenciar o banco de dados local do aplicativo (SQLite).
/// Cria o arquivo do banco, salva as pontuações e realiza as consultas.
/// =====================================================================

class DBHelper {
  // Mantém a conexão ativa com o banco para evitar aberturas repetidas
  // e melhorar o desempenho do aplicativo.
  static Database? _db;

  // Constantes com os nomes do banco e da tabela para evitar erros de
  // digitação ao longo do código.
  static const String _dbName = "missao_reciclar.db";
  static const String _tableName = "scores";

  /// -------------------------------------------------------------------
  /// OBTER CONEXÃO COM O BANCO
  /// -------------------------------------------------------------------
  static Future<Database> get database async {
    // Retorna a conexão se o banco já estiver aberto.
    if (_db != null) return _db!;
    // Inicia a conexão caso seja o primeiro acesso.
    _db = await _initDB();
    return _db!;
  }

  /// -------------------------------------------------------------------
  /// INICIALIZAR E ATUALIZAR O BANCO DE DADOS
  /// -------------------------------------------------------------------
  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      // IMPORTANTE: Para alterar a estrutura da tabela (ex: adicionar colunas)
      // ou zerar o banco local, é necessário aumentar o número desta versão.
      version: 3,

      // onCreate: Executado apenas na primeira vez que o aplicativo é instalado.
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            score INTEGER,
            sincronizado INTEGER DEFAULT 0 
          )
        ''');
      },

      // onUpgrade: Executado quando o aplicativo é atualizado com uma versão de banco maior.
      onUpgrade: (db, oldVersion, newVersion) async {
        // Versão 2: Adiciona a coluna para controle de sincronização com a nuvem.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN sincronizado INTEGER DEFAULT 0',
          );
        }

        // Versão 3: Apaga a tabela antiga e recria a estrutura atualizada.
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await db.execute('''
            CREATE TABLE $_tableName(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              score INTEGER,
              sincronizado INTEGER DEFAULT 0 
            )
          ''');
        }

        /* // ===========================================================
        // CÓDIGO DE EMERGÊNCIA: ZERAR O BANCO LOCAL
        // Para forçar a recriação da tabela no dispositivo dos usuários,
        // altere a "version: 3" (acima) para "version: 4" e descomente 
        // o bloco abaixo.
        // ===========================================================
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await db.execute('''
            CREATE TABLE $_tableName(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              score INTEGER,
              sincronizado INTEGER DEFAULT 0 
            )
          ''');
        }
        */
      },
    );
  }

  /// -------------------------------------------------------------------
  /// SALVAR PONTUAÇÃO LOCALMENTE
  /// -------------------------------------------------------------------
  static Future<void> insertScore(String name, int score) async {
    final db = await database;

    // 1. Verifica se o jogador já existe na tabela local.
    final List<Map<String, dynamic>> jogadorExistente = await db.query(
      _tableName,
      where: "name = ?",
      whereArgs: [name],
    );

    if (jogadorExistente.isNotEmpty) {
      // 2. Se existir, recupera a pontuação antiga registrada.
      int pontuacaoAntiga = jogadorExistente.first['score'] as int;

      // 3. Atualiza no banco apenas se a nova pontuação for um recorde maior.
      if (score > pontuacaoAntiga) {
        await db.update(
          _tableName,
          {
            'score': score,
            'sincronizado':
                0, // 0 indica que o novo recorde precisa ir para a nuvem
          },
          where: "name = ?",
          whereArgs: [name],
        );
      }
    } else {
      // 4. Caso seja um jogador novo, cadastra um registro inédito.
      await db.insert(_tableName, {
        'name': name,
        'score': score,
        'sincronizado': 0,
      });
    }
  }

  /// -------------------------------------------------------------------
  /// CONSULTAR RANKING LOCAL (TOP 10)
  /// Utilizado para exibir a tela de ranking quando não há internet.
  /// -------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getScores() async {
    final db = await database;
    // ORDER BY DESC garante que as maiores pontuações apareçam primeiro.
    return await db.query(_tableName, orderBy: "score DESC", limit: 10);
  }

  /// -------------------------------------------------------------------
  /// CONSULTAR PONTUAÇÕES PENDENTES DE SINCRONIZAÇÃO
  /// -------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getUnsyncedScores() async {
    final db = await database;
    // Retorna todos os registros que ainda não foram enviados para o Supabase.
    return await db.query(
      _tableName,
      where: "sincronizado = ?",
      whereArgs: [0],
    );
  }

  /// -------------------------------------------------------------------
  /// MARCAR REGISTROS COMO SINCRONIZADOS
  /// -------------------------------------------------------------------
  static Future<void> markAsSynced(List<int> ids) async {
    final db = await database;

    // O 'batch' executa várias atualizações ao mesmo tempo, economizando
    // processamento do dispositivo.
    Batch batch = db.batch();

    for (int id in ids) {
      batch.update(
        _tableName,
        {'sincronizado': 1}, // 1 indica que o envio para a nuvem foi concluído
        where: "id = ?",
        whereArgs: [id],
      );
    }

    await batch.commit(); // Efetiva todas as alterações no banco de uma vez
  }

  /// -------------------------------------------------------------------
  /// LIMPAR TODOS OS REGISTROS DA TABELA
  /// -------------------------------------------------------------------
  static Future<void> clearScores() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
