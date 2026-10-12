import 'package:flutter_test/flutter_test.dart';
import 'package:tm_porones/models/cotizacion.dart';

void main() {
  group('Cotizacion', () {
    final base = Cotizacion(
      id: 'abc',
      fecha: DateTime(2026, 3, 1, 10, 0),
      numero: 7,
      cliente: 'Juan',
      obra: 'Casa',
      items: [
        MaterialItem(
            id: 'i1',
            nombre: 'Cemento',
            categoria: 'cemento',
            cantidad: 10,
            precioUnitario: 32000,
            unidad: 'bolsa',
            subtotal: 320000),
      ],
      total: 320000,
      notas: 'urgente',
    );

    test('serialización ida y vuelta', () {
      final json = base.toJson();
      final back = Cotizacion.fromJson(json);
      expect(back.id, 'abc');
      expect(back.numero, 7);
      expect(back.cliente, 'Juan');
      expect(back.estado, EstadoCotizacion.borrador);
      expect(back.items.length, 1);
      expect(back.items.first.subtotal, 320000);
      expect(back.total, 320000);
    });

    test('estado por defecto es borrador', () {
      expect(base.estado, EstadoCotizacion.borrador);
      expect(EstadoCotizacion.label(EstadoCotizacion.aceptada), 'Aceptada');
    });

    test('copyWith cambia solo lo indicado', () {
      final c = base.copyWith(estado: EstadoCotizacion.enviada);
      expect(c.estado, EstadoCotizacion.enviada);
      expect(c.numero, base.numero);
      expect(c.total, base.total);
    });

    test('duplicar genera nuevo id, número y vuelve a borrador', () {
      final d = base.duplicar(id: 'nuevo', numero: 8);
      expect(d.id, 'nuevo');
      expect(d.numero, 8);
      expect(d.estado, EstadoCotizacion.borrador);
      expect(d.items.length, base.items.length);
      expect(d.total, base.total);
    });

    test('MaterialItem.copyWith recalcula el subtotal', () {
      final it = base.items.first.copyWith(cantidad: 20);
      expect(it.cantidad, 20);
      expect(it.subtotal, 20 * 32000);
    });

    test('migración de cotizaciones legacy (v1 sin items)', () {
      final legacy = Cotizacion.fromJson({
        'id': 'old',
        'fecha': DateTime(2025, 1, 1).toIso8601String(),
        'numero': 1,
        'total': 1100000,
        'm2': 50,
        'precioM2': 22000,
        'm3': 0,
        'precioM3': 0,
      });
      expect(legacy.items.length, 1);
      expect(legacy.items.first.unidad, 'm²');
      expect(legacy.items.first.subtotal, 50 * 22000);
    });
  });

  group('AppPrecios', () {
    test('serialización ida y vuelta', () {
      final p = const AppPrecios().copyWith(precioM2: 25000, precioCemento: 40000);
      final back = AppPrecios.fromJson(p.toJson());
      expect(back.precioM2, 25000);
      expect(back.precioCemento, 40000);
    });

    test('migración de precioVarilla3_8', () {
      final p = AppPrecios.fromJson({'precioVarilla3_8': 5000});
      expect(p.precioVarilla, 5000);
    });
  });
}
