import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';

/// =====================================================================
/// CLASSE AppButtons
/// Centraliza os estilos de botões utilizados em todo o aplicativo.
/// Garante a consistência visual das interfaces e facilita a manutenção,
/// permitindo alterar o design global dos botões em um único arquivo.
/// =====================================================================

class AppButtons {
  // BOTÃO PRIMÁRIO
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.orange,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    textStyle: AppText.button,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(150, 50),
  );

  // BOTÃO SECUNDÁRIO
  static ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.darkBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    textStyle: AppText.button,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(150, 50),
  );
}
