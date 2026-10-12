/// Datos de la empresa que aparecen como encabezado de las cotizaciones PDF.
///
/// Es opcional: si está vacía, el PDF usa la marca genérica "T&M".
class Empresa {
  final String nombre;
  final String nit;
  final String telefono;
  final String email;
  final String direccion;
  final String ciudad;

  const Empresa({
    this.nombre = '',
    this.nit = '',
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.ciudad = '',
  });

  bool get isEmpty => nombre.trim().isEmpty;

  Empresa copyWith({
    String? nombre,
    String? nit,
    String? telefono,
    String? email,
    String? direccion,
    String? ciudad,
  }) =>
      Empresa(
        nombre: nombre ?? this.nombre,
        nit: nit ?? this.nit,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        direccion: direccion ?? this.direccion,
        ciudad: ciudad ?? this.ciudad,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'nit': nit,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'ciudad': ciudad,
      };

  factory Empresa.fromJson(Map<String, dynamic> j) => Empresa(
        nombre: j['nombre'] as String? ?? '',
        nit: j['nit'] as String? ?? '',
        telefono: j['telefono'] as String? ?? '',
        email: j['email'] as String? ?? '',
        direccion: j['direccion'] as String? ?? '',
        ciudad: j['ciudad'] as String? ?? '',
      );
}
