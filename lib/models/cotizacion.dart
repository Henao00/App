// ─────────────────────────────────────────────────────────────
// MODELOS — T&M Cotizador v2
// ─────────────────────────────────────────────────────────────

class MaterialItem {
  final String id;
  final String nombre;
  final String categoria;
  final double cantidad;
  final double precioUnitario;
  final String unidad;
  final double subtotal;

  MaterialItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.precioUnitario,
    required this.unidad,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'unidad': unidad,
        'subtotal': subtotal,
      };

  factory MaterialItem.fromJson(Map<String, dynamic> j) => MaterialItem(
        id: j['id'],
        nombre: j['nombre'],
        categoria: j['categoria'] ?? 'custom',
        cantidad: (j['cantidad'] as num).toDouble(),
        precioUnitario: (j['precioUnitario'] as num).toDouble(),
        unidad: j['unidad'] ?? 'und',
        subtotal: (j['subtotal'] as num).toDouble(),
      );

  MaterialItem copyWith({double? cantidad, double? precioUnitario}) =>
      MaterialItem(
        id: id,
        nombre: nombre,
        categoria: categoria,
        cantidad: cantidad ?? this.cantidad,
        precioUnitario: precioUnitario ?? this.precioUnitario,
        unidad: unidad,
        subtotal: (cantidad ?? this.cantidad) * (precioUnitario ?? this.precioUnitario),
      );
}

/// Estados de seguimiento de una cotización.
class EstadoCotizacion {
  static const borrador = 'borrador';
  static const enviada = 'enviada';
  static const aceptada = 'aceptada';
  static const rechazada = 'rechazada';

  static const todos = [borrador, enviada, aceptada, rechazada];

  static String label(String e) => switch (e) {
        enviada => 'Enviada',
        aceptada => 'Aceptada',
        rechazada => 'Rechazada',
        _ => 'Borrador',
      };
}

class Cotizacion {
  final String id;
  final DateTime fecha;
  final int numero;
  final String cliente;
  final String obra;
  final List<MaterialItem> items;
  final double total;
  final String notas;
  final String estado;

  // campos legacy porones
  final double m2;
  final double m3;
  final double alturaPoron;
  final double m3Calculado;
  final double precioM2;
  final double precioM3;
  final double subTotalM2;
  final double subTotalM3;

  Cotizacion({
    required this.id,
    required this.fecha,
    required this.numero,
    this.cliente = '',
    this.obra = '',
    required this.items,
    required this.total,
    required this.notas,
    this.estado = EstadoCotizacion.borrador,
    this.m2 = 0,
    this.m3 = 0,
    this.alturaPoron = 0.25,
    this.m3Calculado = 0,
    this.precioM2 = 0,
    this.precioM3 = 0,
    this.subTotalM2 = 0,
    this.subTotalM3 = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'numero': numero,
        'cliente': cliente,
        'obra': obra,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'notas': notas,
        'estado': estado,
        'm2': m2,
        'm3': m3,
        'alturaPoron': alturaPoron,
        'm3Calculado': m3Calculado,
        'precioM2': precioM2,
        'precioM3': precioM3,
        'subTotalM2': subTotalM2,
        'subTotalM3': subTotalM3,
      };

  factory Cotizacion.fromJson(Map<String, dynamic> j) {
    List<MaterialItem> items = [];
    if (j['items'] != null) {
      items = (j['items'] as List).map((e) => MaterialItem.fromJson(e)).toList();
    } else {
      final m2  = (j['m2'] as num?)?.toDouble() ?? 0;
      final m3  = (j['m3'] as num?)?.toDouble() ?? 0;
      final pM2 = (j['precioM2'] as num?)?.toDouble() ?? 22000;
      final pM3 = (j['precioM3'] as num?)?.toDouble() ?? 0;
      if (m2 > 0) items.add(MaterialItem(id:'legacy_m2', nombre:'Porones (m²)', categoria:'poron', cantidad:m2, precioUnitario:pM2, unidad:'m²', subtotal:m2*pM2));
      if (m3 > 0) items.add(MaterialItem(id:'legacy_m3', nombre:'Porones (m³)', categoria:'poron', cantidad:m3, precioUnitario:pM3, unidad:'m³', subtotal:m3*pM3));
    }
    return Cotizacion(
      id: j['id'], fecha: DateTime.parse(j['fecha']), numero: j['numero'],
      cliente: j['cliente'] ?? '', obra: j['obra'] ?? '',
      items: items, total: (j['total'] as num).toDouble(), notas: j['notas'] ?? '',
      estado: j['estado'] as String? ?? EstadoCotizacion.borrador,
      m2: (j['m2'] as num?)?.toDouble() ?? 0,
      m3: (j['m3'] as num?)?.toDouble() ?? 0,
      alturaPoron: (j['alturaPoron'] as num?)?.toDouble() ?? 0.25,
      m3Calculado: (j['m3Calculado'] as num?)?.toDouble() ?? 0,
      precioM2: (j['precioM2'] as num?)?.toDouble() ?? 0,
      precioM3: (j['precioM3'] as num?)?.toDouble() ?? 0,
      subTotalM2: (j['subTotalM2'] as num?)?.toDouble() ?? 0,
      subTotalM3: (j['subTotalM3'] as num?)?.toDouble() ?? 0,
    );
  }

  Cotizacion copyWith({
    int? numero,
    DateTime? fecha,
    String? cliente,
    String? obra,
    List<MaterialItem>? items,
    double? total,
    String? notas,
    String? estado,
  }) =>
      Cotizacion(
        id: id,
        fecha: fecha ?? this.fecha,
        numero: numero ?? this.numero,
        cliente: cliente ?? this.cliente,
        obra: obra ?? this.obra,
        items: items ?? this.items,
        total: total ?? this.total,
        notas: notas ?? this.notas,
        estado: estado ?? this.estado,
        m2: m2,
        m3: m3,
        alturaPoron: alturaPoron,
        m3Calculado: m3Calculado,
        precioM2: precioM2,
        precioM3: precioM3,
        subTotalM2: subTotalM2,
        subTotalM3: subTotalM3,
      );

  /// Nueva cotización con el mismo contenido pero nuevo id/número/fecha.
  Cotizacion duplicar({required String id, required int numero, DateTime? fecha}) =>
      copyWith(numero: numero, fecha: fecha ?? DateTime.now(), estado: EstadoCotizacion.borrador)
          ._withId(id);

  Cotizacion _withId(String newId) => Cotizacion(
        id: newId,
        fecha: fecha,
        numero: numero,
        cliente: cliente,
        obra: obra,
        items: items,
        total: total,
        notas: notas,
        estado: estado,
        m2: m2,
        m3: m3,
        alturaPoron: alturaPoron,
        m3Calculado: m3Calculado,
        precioM2: precioM2,
        precioM3: precioM3,
        subTotalM2: subTotalM2,
        subTotalM3: subTotalM3,
      );
}

class MaterialPreset {
  final String id;
  final String nombre;
  final double precioUnitario;
  final String unidad;

  MaterialPreset({required this.id, required this.nombre, required this.precioUnitario, required this.unidad});

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'precioUnitario': precioUnitario, 'unidad': unidad};

  factory MaterialPreset.fromJson(Map<String, dynamic> j) => MaterialPreset(
        id: j['id'], nombre: j['nombre'],
        precioUnitario: (j['precioUnitario'] as num).toDouble(),
        unidad: j['unidad'] ?? 'und',
      );
}

class AppPrecios {
  final double precioM2;
  final double precioM3;
  final double alturaDefault;
  // Cemento (separado de arena)
  final double precioCemento;      // por bolsa 50kg
  // Arena (separada)
  final double precioArena;        // por m³
  // Varilla unificada con precio base por ml
  final double precioVarilla;      // precio base por ml
  // Ladrillo/bloque
  final double precioLadrillo;
  final double precioBloque;
  // Pintura/acabados
  final double precioPintura;
  final double precioStucco;
  // Materiales personalizados
  final List<MaterialPreset> customMateriales;

  const AppPrecios({
    this.precioM2 = 22000,
    this.precioM3 = 0,
    this.alturaDefault = 0.25,
    this.precioCemento = 32000,
    this.precioArena = 85000,
    this.precioVarilla = 4500,
    this.precioLadrillo = 850,
    this.precioBloque = 2200,
    this.precioPintura = 18000,
    this.precioStucco = 3500,
    this.customMateriales = const [],
  });

  AppPrecios copyWith({
    double? precioM2, double? precioM3, double? alturaDefault,
    double? precioCemento, double? precioArena, double? precioVarilla,
    double? precioLadrillo, double? precioBloque,
    double? precioPintura, double? precioStucco,
    List<MaterialPreset>? customMateriales,
  }) => AppPrecios(
    precioM2: precioM2 ?? this.precioM2,
    precioM3: precioM3 ?? this.precioM3,
    alturaDefault: alturaDefault ?? this.alturaDefault,
    precioCemento: precioCemento ?? this.precioCemento,
    precioArena: precioArena ?? this.precioArena,
    precioVarilla: precioVarilla ?? this.precioVarilla,
    precioLadrillo: precioLadrillo ?? this.precioLadrillo,
    precioBloque: precioBloque ?? this.precioBloque,
    precioPintura: precioPintura ?? this.precioPintura,
    precioStucco: precioStucco ?? this.precioStucco,
    customMateriales: customMateriales ?? this.customMateriales,
  );

  Map<String, dynamic> toJson() => {
    'precioM2': precioM2, 'precioM3': precioM3, 'alturaDefault': alturaDefault,
    'precioCemento': precioCemento, 'precioArena': precioArena,
    'precioVarilla': precioVarilla,
    'precioLadrillo': precioLadrillo, 'precioBloque': precioBloque,
    'precioPintura': precioPintura, 'precioStucco': precioStucco,
    'customMateriales': customMateriales.map((e) => e.toJson()).toList(),
  };

  factory AppPrecios.fromJson(Map<String, dynamic> j) => AppPrecios(
    precioM2: (j['precioM2'] as num?)?.toDouble() ?? 22000,
    precioM3: (j['precioM3'] as num?)?.toDouble() ?? 0,
    alturaDefault: (j['alturaDefault'] as num?)?.toDouble() ?? 0.25,
    precioCemento: (j['precioCemento'] as num?)?.toDouble() ?? 32000,
    precioArena: (j['precioArena'] as num?)?.toDouble() ?? 85000,
    // migración: si tenía precioVarilla3_8 usa ese, sino precioVarilla
    precioVarilla: (j['precioVarilla'] as num?)?.toDouble() ??
                   (j['precioVarilla3_8'] as num?)?.toDouble() ?? 4500,
    precioLadrillo: (j['precioLadrillo'] as num?)?.toDouble() ?? 850,
    precioBloque: (j['precioBloque'] as num?)?.toDouble() ?? 2200,
    precioPintura: (j['precioPintura'] as num?)?.toDouble() ?? 18000,
    precioStucco: (j['precioStucco'] as num?)?.toDouble() ?? 3500,
    customMateriales: j['customMateriales'] != null
        ? (j['customMateriales'] as List).map((e) => MaterialPreset.fromJson(e)).toList()
        : [],
  );
}
