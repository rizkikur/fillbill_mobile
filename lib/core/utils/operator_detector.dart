import 'package:flutter/material.dart';

enum CellularOperatorType {
  telkomsel,
  indosat,
  xl,
  axis,
  tri,
  smartfren,
  unknown,
}

class CellularOperatorInfo {
  final CellularOperatorType type;
  final String name;
  final String code;
  final Color primaryColor;
  final IconData icon;

  const CellularOperatorInfo({
    required this.type,
    required this.name,
    required this.code,
    required this.primaryColor,
    required this.icon,
  });
}

class OperatorDetector {
  OperatorDetector._();

  static const Map<String, CellularOperatorType> _prefixMap = {
    // Telkomsel (SimPATI, Kartu As, Loop, By.U)
    '0811': CellularOperatorType.telkomsel,
    '0812': CellularOperatorType.telkomsel,
    '0813': CellularOperatorType.telkomsel,
    '0821': CellularOperatorType.telkomsel,
    '0822': CellularOperatorType.telkomsel,
    '0823': CellularOperatorType.telkomsel,
    '0851': CellularOperatorType.telkomsel,
    '0852': CellularOperatorType.telkomsel,
    '0853': CellularOperatorType.telkomsel,

    // Indosat Ooredoo (IM3, Mentari)
    '0814': CellularOperatorType.indosat,
    '0815': CellularOperatorType.indosat,
    '0816': CellularOperatorType.indosat,
    '0855': CellularOperatorType.indosat,
    '0856': CellularOperatorType.indosat,
    '0857': CellularOperatorType.indosat,
    '0858': CellularOperatorType.indosat,

    // XL Axiata
    '0817': CellularOperatorType.xl,
    '0818': CellularOperatorType.xl,
    '0819': CellularOperatorType.xl,
    '0859': CellularOperatorType.xl,
    '0877': CellularOperatorType.xl,
    '0878': CellularOperatorType.xl,

    // Axis
    '0831': CellularOperatorType.axis,
    '0832': CellularOperatorType.axis,
    '0833': CellularOperatorType.axis,
    '0838': CellularOperatorType.axis,

    // Tri (3)
    '0895': CellularOperatorType.tri,
    '0896': CellularOperatorType.tri,
    '0897': CellularOperatorType.tri,
    '0898': CellularOperatorType.tri,
    '0899': CellularOperatorType.tri,

    // Smartfren
    '0881': CellularOperatorType.smartfren,
    '0882': CellularOperatorType.smartfren,
    '0883': CellularOperatorType.smartfren,
    '0884': CellularOperatorType.smartfren,
    '0885': CellularOperatorType.smartfren,
    '0886': CellularOperatorType.smartfren,
    '0887': CellularOperatorType.smartfren,
    '0888': CellularOperatorType.smartfren,
    '0889': CellularOperatorType.smartfren,
  };

  /// Deteksi operator seluler lokal secara instan (0ms, tanpa hit API)
  static CellularOperatorInfo detect(String rawPhone) {
    String clean = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (clean.startsWith('62')) {
      clean = '0${clean.substring(2)}';
    } else if (!clean.startsWith('0') && clean.isNotEmpty) {
      clean = '0$clean';
    }

    if (clean.length >= 4) {
      final prefix = clean.substring(0, 4);
      final opType = _prefixMap[prefix];
      if (opType != null) {
        return getInfo(opType);
      }
    }

    return const CellularOperatorInfo(
      type: CellularOperatorType.unknown,
      name: 'Nomor Ponsel',
      code: 'unknown',
      primaryColor: Colors.grey,
      icon: Icons.phone_android,
    );
  }

  static CellularOperatorInfo getInfo(CellularOperatorType type) {
    switch (type) {
      case CellularOperatorType.telkomsel:
        return const CellularOperatorInfo(
          type: CellularOperatorType.telkomsel,
          name: 'Telkomsel',
          code: 'telkomsel',
          primaryColor: Color(0xFFED1C24),
          icon: Icons.cell_tower,
        );
      case CellularOperatorType.indosat:
        return const CellularOperatorInfo(
          type: CellularOperatorType.indosat,
          name: 'Indosat Ooredoo',
          code: 'indosat',
          primaryColor: Color(0xFFFFB800),
          icon: Icons.wifi_tethering,
        );
      case CellularOperatorType.xl:
        return const CellularOperatorInfo(
          type: CellularOperatorType.xl,
          name: 'XL Axiata',
          code: 'xl',
          primaryColor: Color(0xFF005BAA),
          icon: Icons.network_cell,
        );
      case CellularOperatorType.axis:
        return const CellularOperatorInfo(
          type: CellularOperatorType.axis,
          name: 'Axis',
          code: 'axis',
          primaryColor: Color(0xFF7B1FA2),
          icon: Icons.flash_on,
        );
      case CellularOperatorType.tri:
        return const CellularOperatorInfo(
          type: CellularOperatorType.tri,
          name: 'Tri (3)',
          code: 'tri',
          primaryColor: Color(0xFFFF5722),
          icon: Icons.signal_cellular_alt,
        );
      case CellularOperatorType.smartfren:
        return const CellularOperatorInfo(
          type: CellularOperatorType.smartfren,
          name: 'Smartfren',
          code: 'smartfren',
          primaryColor: Color(0xFFE91E63),
          icon: Icons.bolt,
        );
      case CellularOperatorType.unknown:
        return const CellularOperatorInfo(
          type: CellularOperatorType.unknown,
          name: 'Nomor Ponsel',
          code: 'unknown',
          primaryColor: Colors.grey,
          icon: Icons.phone_android,
        );
    }
  }
}

