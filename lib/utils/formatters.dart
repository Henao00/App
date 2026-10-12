import 'package:intl/intl.dart';

/// Utilidades de formato y parseo centralizadas (locale es-CO).
///
/// Antes cada pantalla definía su propio `NumberFormat`/`DateFormat`; además
/// el parseo usaba `double.tryParse`, que falla con la coma decimal del usuario
/// colombiano. Aquí se unifica todo en un solo lugar.
class TmFormat {
  TmFormat._();

  static final NumberFormat _plain = NumberFormat('#,##0', 'es_CO');
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'es_CO');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es_CO');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'es_CO');
  static final DateFormat _short = DateFormat('dd/MM/yy', 'es_CO');

  /// `12500` -> `$12.500` (con símbolo incluido).
  static String cop(num v) => '\$${_plain.format(v)}';

  /// `12500` -> `12.500` (sin símbolo, para concatenar a mano).
  static String copPlain(num v) => _plain.format(v);

  /// Cantidad legible: enteros sin decimales, el resto con 2.
  static String qty(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String shortDate(DateTime d) => _short.format(d);

  /// Parseo robusto de números "a la colombiana".
  ///
  /// Acepta `12,5`, `12.5`, `1.234,56`, `1,234.56`, `22000`, `$ 12.500`.
  static double? parseNum(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().replaceAll(RegExp(r'[^0-9.,\-]'), '');
    if (s.isEmpty) return null;

    final comma = s.lastIndexOf(',');
    final dot = s.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      if (comma > dot) {
        // 1.234,56 -> el último separador es la coma decimal
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,234.56 -> el punto es decimal
        s = s.replaceAll(',', '');
      }
    } else if (comma >= 0) {
      // En es-CO la coma es decimal
      s = s.replaceAll(',', '.');
    } else if (dot >= 0) {
      final after = s.length - dot - 1;
      final dots = RegExp(r'\.').allMatches(s).length;
      // 1.234 -> miles ; 12.5 -> decimal
      if (dots > 1 || (after == 3 && dot <= 3)) {
        s = s.replaceAll('.', '');
      }
    }
    return double.tryParse(s);
  }

  /// Igual que [parseNum] pero devuelve `0` cuando no se puede parsear.
  static double parseNumOrZero(String? raw) => parseNum(raw) ?? 0;
}
