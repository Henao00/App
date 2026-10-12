import 'package:flutter_test/flutter_test.dart';
import 'package:tm_porones/utils/formatters.dart';

void main() {
  group('TmFormat.parseNum (locale es-CO)', () {
    test('enteros simples', () {
      expect(TmFormat.parseNum('22000'), 22000);
      expect(TmFormat.parseNum('0'), 0);
    });

    test('coma como decimal', () {
      expect(TmFormat.parseNum('12,5'), 12.5);
      expect(TmFormat.parseNum('0,25'), 0.25);
    });

    test('punto como decimal', () {
      expect(TmFormat.parseNum('12.5'), 12.5);
      expect(TmFormat.parseNum('0.25'), 0.25);
    });

    test('miles con punto (es-CO)', () {
      expect(TmFormat.parseNum('1.234'), 1234);
      expect(TmFormat.parseNum('12.500'), 12500);
      expect(TmFormat.parseNum('1.000.000'), 1000000);
    });

    test('miles + decimal', () {
      expect(TmFormat.parseNum('1.234,56'), 1234.56);
      expect(TmFormat.parseNum('1,234.56'), 1234.56);
    });

    test('ignora símbolos de moneda', () {
      expect(TmFormat.parseNum('\$ 12.500'), 12500);
    });

    test('valores inválidos devuelven null', () {
      expect(TmFormat.parseNum(''), isNull);
      expect(TmFormat.parseNum('abc'), isNull);
      expect(TmFormat.parseNum(null), isNull);
      expect(TmFormat.parseNum(','), isNull);
    });

    test('parseNumOrZero', () {
      expect(TmFormat.parseNumOrZero('abc'), 0);
      expect(TmFormat.parseNumOrZero('3,5'), 3.5);
    });
  });

  group('TmFormat.qty', () {
    test('enteros sin decimales', () => expect(TmFormat.qty(12), '12'));
    test('decimales con 2 dígitos', () => expect(TmFormat.qty(12.5), '12.50'));
  });

  group('TmFormat.cop', () {
    test('formatea con símbolo y separador de miles', () {
      expect(TmFormat.cop(12500), '\$12.500');
      expect(TmFormat.copPlain(12500), '12.500');
    });
  });
}
