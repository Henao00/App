import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm_porones/models/cotizacion.dart';
import 'package:tm_porones/models/empresa.dart';
import 'package:tm_porones/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StorageService();
  });

  Cotizacion nueva(int numero) => Cotizacion(
        id: 'id$numero',
        fecha: DateTime(2026, 1, numero),
        numero: numero,
        items: const [],
        total: numero * 1000,
        notas: '',
      );

  group('StorageService — cotizaciones', () {
    test('guarda y recupera', () async {
      await store.saveCotizacion(nueva(1));
      await store.saveCotizacion(nueva(2));
      final list = await store.loadCotizaciones();
      expect(list.length, 2);
      // la más reciente queda primero
      expect(list.first.numero, 2);
    });

    test('update reemplaza por id sin duplicar', () async {
      await store.saveCotizacion(nueva(1));
      await store.updateCotizacion(nueva(1).copyWith(estado: EstadoCotizacion.aceptada));
      final list = await store.loadCotizaciones();
      expect(list.length, 1);
      expect(list.first.estado, EstadoCotizacion.aceptada);
    });

    test('eliminar por id', () async {
      await store.saveCotizacion(nueva(1));
      await store.saveCotizacion(nueva(2));
      await store.deleteCotizacion('id1');
      final list = await store.loadCotizaciones();
      expect(list.length, 1);
      expect(list.first.id, 'id2');
    });

    test('datos corruptos no tumban la app', () async {
      SharedPreferences.setMockInitialValues({'cotizaciones_v1': 'esto no es json'});
      final s = StorageService();
      expect(await s.loadCotizaciones(), isEmpty);
    });

    test('registros inválidos se descartan, los válidos se conservan', () async {
      SharedPreferences.setMockInitialValues({
        'cotizaciones_v1': '[{"id":"ok","fecha":"2026-01-01T00:00:00.000","numero":1,"total":100,"items":[]},{"basura":true}]',
      });
      final s = StorageService();
      final list = await s.loadCotizaciones();
      expect(list.length, 1);
      expect(list.first.id, 'ok');
    });
  });

  group('StorageService — contador', () {
    test('nextNumero no consume hasta commit', () async {
      expect(await store.nextNumero(), 1);
      expect(await store.nextNumero(), 1); // sigue siendo 1
      await store.commitNumero(1);
      expect(await store.nextNumero(), 2);
    });

    test('commit no retrocede el contador', () async {
      await store.commitNumero(5);
      await store.commitNumero(3);
      expect(await store.nextNumero(), 6);
    });
  });

  group('StorageService — precios y empresa', () {
    test('defaults cuando no hay nada guardado', () async {
      final p = await store.loadPrecios();
      expect(p.precioM2, 22000);
      final e = await store.loadEmpresa();
      expect(e.isEmpty, true);
    });

    test('guarda y recupera precios/empresa', () async {
      await store.savePrecios(const AppPrecios().copyWith(precioM2: 30000));
      await store.saveEmpresa(const Empresa(nombre: 'T&M SAS', nit: '900123'));
      expect((await store.loadPrecios()).precioM2, 30000);
      final e = await store.loadEmpresa();
      expect(e.nombre, 'T&M SAS');
      expect(e.nit, '900123');
    });

    test('precios corruptos devuelven defaults', () async {
      SharedPreferences.setMockInitialValues({'precios_v1': '{{{no-json'});
      final s = StorageService();
      expect((await s.loadPrecios()).precioM2, 22000);
    });
  });

  group('StorageService — onboarding', () {
    test('primera ejecución vs completado', () async {
      expect(await store.isFirstRun(), true);
      await store.completeOnboarding();
      expect(await store.isFirstRun(), false);
    });
  });
}
