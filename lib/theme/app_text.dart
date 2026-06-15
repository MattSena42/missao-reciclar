import 'package:flutter/material.dart';
import 'app_colors.dart';

/// =====================================================================
/// CLASSE AppText
/// Centraliza a tipografia (estilos de texto) de todo o aplicativo.
/// Trabalha em conjunto com o arquivo de cores para garantir que todos
/// os textos sigam o mesmo padrão visual e a mesma fonte personalizada,
/// facilitando a manutenção e a escalabilidade da interface.
/// =====================================================================

class AppText {
  // ESTILO DE TÍTULO
  static const TextStyle title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Archive',
    color: AppColors.darkBlue,
  );

  // ESTILO DE BOTÃO
  static const TextStyle button = TextStyle(
    fontSize: 20,
    fontFamily: 'Archive',
    color: Colors.white,
  );

  // ESTILO DE CORPO DE TEXTO
  static const TextStyle body = TextStyle(
    fontSize: 18,
    fontFamily: 'Archive',
    color: AppColors.blueGrey,
  );
}
