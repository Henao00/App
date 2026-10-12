import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cotizacion.dart';
import '../models/empresa.dart';

/// Contrato de persistencia.
///
/// Las pantallas dependen de esta interfaz, no de la implementación. Así se
/// puede sustituir [StorageService] por una versión en la nube
/// (Firebase/Supabase) sin modificar la UI.
abstract class TmStore {
  Future<AppPrecios> loadPrecios();
  Future<void> savePrecios(AppPrecios precios);

  Future<Empresa> loadEmpresa();
  Future<void> saveEmpresa(Empresa empresa);

  Future<List<Cotizacion>> loadCotizaciones();
  Future<void> saveCotizacion(Cotizacion c);
  Future<void> updateCotizacion(Cotizacion c);
  Future<void> deleteCotizacion(String id);
  Future<void> deleteAll();

  /// Siguiente número disponible, sin consumirlo.
  Future<int> nextNumero();

  /// Consolida [numero] como consecutivo usado (solo tras guardar con éxito).
  Future<void> commitNumero(int numero);

  Future<bool> isFirstRun();
  Future<void> completeOnboarding();
}

/// Implementación local sobre SharedPreferences.
///
/// Endurecida: nunca lanza por datos corruptos (los descarta y sigue), y antes
/// de sobrescribir guarda una copia de seguridad del último estado válido.
class StorageService implements TmStore {
  static const _keyCotizaciones = 'cotizaciones_v1';
  static const _keyPrecios = 'precios_v1';
  static const _keyEmpresa = 'empresa_v1';
  static const _keyContador = 'contador_v1';
  static const _keyOnboarding = 'onboarding_done_v1';
  static const _keyBackup = 'cotizaciones_backup_v1';

  // ─── PRECIOS ───────────────────────────────────────────
  @override
  Future<AppPrecios> loadPrecios() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _tryDecodeMap(prefs.getString(_keyPrecios));
    if (map == null) return const AppPrecios();
    try {
      return AppPrecios.fromJson(map);
    } catch (_) {
      return const AppPrecios();
    }
  }

  @override
  Future<void> savePrecios(AppPrecios precios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrecios, jsonEncode(precios.toJson()));
  }

  // ─── EMPRESA ───────────────────────────────────────────
  @override
  Future<Empresa> loadEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _tryDecodeMap(prefs.getString(_keyEmpresa));
    if (map == null) return const Empresa();
    try {
      return Empresa.fromJson(map);
    } catch (_) {
      return const Empresa();
    }
  }

  @override
  Future<void> saveEmpresa(Empresa empresa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmpresa, jsonEncode(empresa.toJson()));
  }

  // ─── COTIZACIONES ──────────────────────────────────────
  @override
  Future<List<Cotizacion>> loadCotizaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCotizaciones);
    if (raw == null) return [];
    final list = _tryDecodeList(raw);
    if (list == null) return [];
    final out = <Cotizacion>[];
    for (final e in list) {
      try {
        out.add(Cotizacion.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Se ignora el registro corrupto en lugar de tumbar toda la app.
      }
    }
    return out;
  }

  @override
  Future<void> saveCotizacion(Cotizacion c) async {
    final list = await loadCotizaciones();
    list.removeWhere((e) => e.id == c.id);
    list.insert(0, c);
    await _persistList(list);
  }

  @override
  Future<void> updateCotizacion(Cotizacion c) async {
    final list = await loadCotizaciones();
    final i = list.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      list[i] = c;
    } else {
      list.insert(0, c);
    }
    await _persistList(list);
  }

  @override
  Future<void> deleteCotizacion(String id) async {
    final list = await loadCotizaciones();
    list.removeWhere((c) => c.id == id);
    await _persistList(list);
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCotizaciones);
    await prefs.remove(_keyContador);
  }

  Future<void> _persistList(List<Cotizacion> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Copia de seguridad del estado anterior antes de escribir.
    final prev = prefs.getString(_keyCotizaciones);
    if (prev != null) await prefs.setString(_keyBackup, prev);
    await prefs.setString(
        _keyCotizaciones, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ─── CONTADOR ─────────────────────────────────────────
  @override
  Future<int> nextNumero() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_keyContador) ?? 0) + 1;
  }

  // Reserva el número solo cuando el guardado ya fue exitoso.
  @override
  Future<void> commitNumero(int numero) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyContador) ?? 0;
    if (numero > current) await prefs.setInt(_keyContador, numero);
  }

  // ─── ONBOARDING ───────────────────────────────────────
  @override
  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyOnboarding) ?? false);
  }

  @override
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  // ─── Helpers de decodificación segura ─────────────────
  Map<String, dynamic>? _tryDecodeMap(String? raw) {
    if (raw == null) return null;
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? _tryDecodeList(String raw) {
    try {
      final v = jsonDecode(raw);
      return v is List ? v : null;
    } catch (_) {
      return null;
    }
  }
}
