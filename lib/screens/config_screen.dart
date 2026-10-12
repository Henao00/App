import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/cotizacion.dart';
import '../models/empresa.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ConfigScreen extends StatefulWidget {
  final AppPrecios precios;
  final Empresa empresa;
  final ValueChanged<AppPrecios> onSaved;
  final ValueChanged<Empresa> onEmpresaSaved;
  const ConfigScreen({
    super.key,
    required this.precios,
    required this.empresa,
    required this.onSaved,
    required this.onEmpresaSaved,
  });
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _storage = StorageService();
  final _uuid = const Uuid();

  // Empresa
  late final _empNombreCtrl = TextEditingController(text: widget.empresa.nombre);
  late final _empNitCtrl = TextEditingController(text: widget.empresa.nit);
  late final _empTelCtrl = TextEditingController(text: widget.empresa.telefono);
  late final _empEmailCtrl = TextEditingController(text: widget.empresa.email);
  late final _empDirCtrl = TextEditingController(text: widget.empresa.direccion);
  late final _empCiudadCtrl = TextEditingController(text: widget.empresa.ciudad);

  // Porones
  late final _m2Ctrl  = TextEditingController(text: widget.precios.precioM2.toStringAsFixed(0));
  late final _m3Ctrl  = TextEditingController(text: widget.precios.precioM3.toStringAsFixed(0));
  late final _altCtrl = TextEditingController(text: (widget.precios.alturaDefault*100).toStringAsFixed(0));
  // Cemento
  late final _cemCtrl  = TextEditingController(text: widget.precios.precioCemento.toStringAsFixed(0));
  // Arena (separada)
  late final _arenaCtrl = TextEditingController(text: widget.precios.precioArena.toStringAsFixed(0));
  // Varilla unificada
  late final _varCtrl  = TextEditingController(text: widget.precios.precioVarilla.toStringAsFixed(0));
  // Ladrillo/bloque
  late final _ladCtrl  = TextEditingController(text: widget.precios.precioLadrillo.toStringAsFixed(0));
  late final _bloqCtrl = TextEditingController(text: widget.precios.precioBloque.toStringAsFixed(0));
  // Pintura
  late final _pintCtrl = TextEditingController(text: widget.precios.precioPintura.toStringAsFixed(0));
  late final _stucCtrl = TextEditingController(text: widget.precios.precioStucco.toStringAsFixed(0));

  // Custom
  final _cNombreCtrl = TextEditingController();
  final _cPrecioCtrl = TextEditingController();
  String _cUnidad = 'und';
  late List<MaterialPreset> _customs;

  @override
  void initState() {
    super.initState();
    _customs = List.from(widget.precios.customMateriales);
  }

  @override
  void dispose() {
    for (final c in [_empNombreCtrl,_empNitCtrl,_empTelCtrl,_empEmailCtrl,_empDirCtrl,_empCiudadCtrl,
        _m2Ctrl,_m3Ctrl,_altCtrl,_cemCtrl,_arenaCtrl,_varCtrl,_ladCtrl,_bloqCtrl,_pintCtrl,_stucCtrl,
        _cNombreCtrl,_cPrecioCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final p = widget.precios.copyWith(
      precioM2:     TmFormat.parseNum(_m2Ctrl.text)   ?? widget.precios.precioM2,
      precioM3:     TmFormat.parseNum(_m3Ctrl.text)   ?? widget.precios.precioM3,
      alturaDefault:(TmFormat.parseNum(_altCtrl.text) ?? 25) / 100,
      precioCemento:TmFormat.parseNum(_cemCtrl.text)  ?? widget.precios.precioCemento,
      precioArena:  TmFormat.parseNum(_arenaCtrl.text)?? widget.precios.precioArena,
      precioVarilla:TmFormat.parseNum(_varCtrl.text)  ?? widget.precios.precioVarilla,
      precioLadrillo:TmFormat.parseNum(_ladCtrl.text) ?? widget.precios.precioLadrillo,
      precioBloque: TmFormat.parseNum(_bloqCtrl.text) ?? widget.precios.precioBloque,
      precioPintura:TmFormat.parseNum(_pintCtrl.text) ?? widget.precios.precioPintura,
      precioStucco: TmFormat.parseNum(_stucCtrl.text) ?? widget.precios.precioStucco,
      customMateriales: _customs,
    );
    final e = widget.empresa.copyWith(
      nombre: _empNombreCtrl.text.trim(),
      nit: _empNitCtrl.text.trim(),
      telefono: _empTelCtrl.text.trim(),
      email: _empEmailCtrl.text.trim(),
      direccion: _empDirCtrl.text.trim(),
      ciudad: _empCiudadCtrl.text.trim(),
    );
    await _storage.savePrecios(p);
    await _storage.saveEmpresa(e);
    if (!mounted) return;
    widget.onSaved(p);
    widget.onEmpresaSaved(e);
    showTmSnack(context, '✅ Precios y datos guardados');
  }

  void _agregarCustom() {
    final nombre = _cNombreCtrl.text.trim();
    final precio = TmFormat.parseNum(_cPrecioCtrl.text) ?? 0;
    if (nombre.isEmpty || precio <= 0) {
      showTmSnack(context, 'Completa nombre y precio del material', error: true);
      return;
    }
    setState(() {
      _customs.add(MaterialPreset(id:_uuid.v4(), nombre:nombre, precioUnitario:precio, unidad:_cUnidad));
      _cNombreCtrl.clear(); _cPrecioCtrl.clear();
    });
  }

  Future<void> _exportarRespaldo() async {
    final cots = await _storage.loadCotizaciones();
    final data = jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'precios': widget.precios.toJson(),
      'empresa': widget.empresa.toJson(),
      'cotizaciones': cots.map((e) => e.toJson()).toList(),
    });
    try {
      await Share.share(data, subject: 'Respaldo T&M');
    } catch (_) {
      if (mounted) showTmSnack(context, 'No se pudo exportar el respaldo', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── Empresa (marca del PDF) ───────────────
        TmCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const Icon(Icons.business_rounded,color:AppTheme.primary,size:18),
            const SizedBox(width:8),
            Text('Mi empresa',style:GoogleFonts.syne(fontSize:15,fontWeight:FontWeight.w700,color:AppTheme.primary)),
          ]),
          const SizedBox(height:6),
          Text('Estos datos aparecen en el encabezado de las cotizaciones PDF.',
              style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
          const SizedBox(height:12),
          TmInput(controller:_empNombreCtrl,label:'Nombre o razón social',icon:Icons.badge_outlined),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TmInput(controller:_empNitCtrl,label:'NIT / Cédula',icon:Icons.numbers_rounded)),
            const SizedBox(width:8),
            Expanded(child:TmInput(controller:_empTelCtrl,label:'Teléfono',icon:Icons.phone_outlined,keyboardType:TextInputType.phone)),
          ]),
          const SizedBox(height:8),
          TmInput(controller:_empEmailCtrl,label:'Correo',icon:Icons.email_outlined,keyboardType:TextInputType.emailAddress),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TmInput(controller:_empDirCtrl,label:'Dirección',icon:Icons.location_on_outlined)),
            const SizedBox(width:8),
            Expanded(child:TmInput(controller:_empCiudadCtrl,label:'Ciudad',icon:Icons.location_city_rounded)),
          ]),
        ])),
        const SizedBox(height:12),

        // ── Porones ──────────────────────────────
        _seccion('🧱 Porones', AppTheme.primary, [
          _fila(_m2Ctrl,  'Precio por m²',           'm²'),
          _fila(_m3Ctrl,  'Precio por m³',           'm³'),
          _fila(_altCtrl, 'Grosor por defecto',      'cm'),
        ]),
        const SizedBox(height:12),

        // ── Cemento ───────────────────────────────
        _seccion('🏗️ Cemento', const Color(0xFF9AA0B8), [
          _fila(_cemCtrl, 'Cemento (bolsa 50kg)', '\$'),
        ]),
        const SizedBox(height:12),

        // ── Arena ─────────────────────────────────
        _seccion('⛱️ Arena', const Color(0xFFD4A056), [
          _fila(_arenaCtrl, 'Arena (m³)', '\$'),
        ]),
        const SizedBox(height:12),

        // ── Varilla ───────────────────────────────
        _seccion('🔩 Varilla', const Color(0xFF2DCE89), [
          _fila(_varCtrl, 'Precio base por ml', '\$'),
          Padding(padding:const EdgeInsets.only(top:4),
            child:Text('💡 El precio se puede ajustar al cotizar según el diámetro',
                style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary))),
        ]),
        const SizedBox(height:12),

        // ── Ladrillo/Bloque ───────────────────────
        _seccion('🧱 Ladrillo y Bloque', const Color(0xFFE57B5F), [
          _fila(_ladCtrl,  'Ladrillo (und)', '\$'),
          _fila(_bloqCtrl, 'Bloque (und)',   '\$'),
        ]),
        const SizedBox(height:12),

        // ── Pintura ───────────────────────────────
        _seccion('🎨 Pintura y Acabados', const Color(0xFF5E72E4), [
          _fila(_pintCtrl, 'Pintura (litro)', '\$'),
          _fila(_stucCtrl, 'Estuco (kg)',     '\$'),
        ]),
        const SizedBox(height:12),

        // ── Materiales custom ─────────────────────
        TmCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const Icon(Icons.tune_rounded,color:Color(0xFF11CDEF),size:18),
            const SizedBox(width:8),
            Text('Materiales Variables',style:GoogleFonts.syne(fontSize:15,fontWeight:FontWeight.w700,color:const Color(0xFF11CDEF))),
          ]),
          const SizedBox(height:12),
          if (_customs.isNotEmpty) ...[
            ..._customs.map((m)=>Container(
              margin:const EdgeInsets.only(bottom:8),
              padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
              decoration:BoxDecoration(color:AppTheme.bg,borderRadius:BorderRadius.circular(8),
                  border:Border.all(color:AppTheme.border)),
              child:Row(children:[
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(m.nombre,style:GoogleFonts.dmSans(fontSize:13,color:AppTheme.textPrimary,fontWeight:FontWeight.w600)),
                  Text('${TmFormat.cop(m.precioUnitario)} / ${m.unidad}',
                      style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
                ])),
                IconButton(icon:const Icon(Icons.delete_outline_rounded,color:AppTheme.danger,size:18),
                    onPressed:()=>setState(()=>_customs.removeWhere((x)=>x.id==m.id))),
              ]),
            )),
            const Divider(color:AppTheme.border),
          ],
          Text('Agregar nuevo:',style:GoogleFonts.dmSans(fontSize:12,color:AppTheme.textSecondary)),
          const SizedBox(height:8),
          TmInput(controller:_cNombreCtrl,label:'Nombre del material',icon:Icons.label_outline_rounded),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TmInput(controller:_cPrecioCtrl,label:'Precio unitario',icon:Icons.attach_money_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width:8),
            DropdownButton<String>(
              value:_cUnidad,
              dropdownColor:AppTheme.surface,
              style:GoogleFonts.dmSans(fontSize:12,color:AppTheme.textPrimary),
              items:['und','m²','m³','ml','kg','litro','bolsa','rollo']
                  .map((u)=>DropdownMenuItem(value:u,child:Text(u))).toList(),
              onChanged:(v)=>setState(()=>_cUnidad=v!),
            ),
          ]),
          const SizedBox(height:10),
          TmButton(label:'Agregar Material',icon:Icons.add_rounded,color:const Color(0xFF11CDEF),onPressed:_agregarCustom),
        ])),
        const SizedBox(height:16),

        TmButton(label:'Guardar todos los cambios',icon:Icons.save_rounded,onPressed:_guardar,fullWidth:true),
        const SizedBox(height:12),

        // ── Respaldo ──────────────────────────────
        TmCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Respaldo',style:GoogleFonts.syne(fontSize:14,fontWeight:FontWeight.w700,color:AppTheme.textPrimary)),
          const SizedBox(height:6),
          Text('Comparte una copia de tus precios, empresa y cotizaciones (JSON).',
              style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
          const SizedBox(height:10),
          TmButton(label:'Exportar respaldo',icon:Icons.ios_share_rounded,color:AppTheme.surface2,onPressed:_exportarRespaldo,fullWidth:true),
        ])),
        const SizedBox(height:12),

        // ── Zona peligrosa ────────────────────────
        TmCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Zona de peligro',style:GoogleFonts.syne(fontSize:14,fontWeight:FontWeight.w700,color:AppTheme.danger)),
          const SizedBox(height:10),
          TmButton(label:'Borrar todo el historial',icon:Icons.delete_forever_rounded,
              color:AppTheme.danger,fullWidth:true,
              onPressed:() async {
                final ok = await showDialog<bool>(context:context,
                  builder:(_)=>AlertDialog(backgroundColor:AppTheme.surface,
                    title:Text('¿Borrar historial?',style:GoogleFonts.syne(color:AppTheme.danger)),
                    content:Text('Esta acción no se puede deshacer.',style:GoogleFonts.dmSans(color:AppTheme.textSecondary)),
                    actions:[
                      TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),
                      TextButton(onPressed:()=>Navigator.pop(context,true),child:Text('Borrar',style:const TextStyle(color:AppTheme.danger))),
                    ]));
                if (ok==true) {
                  await _storage.deleteAll();
                  if (mounted) showTmSnack(context, 'Historial borrado');
                }
              }),
        ])),
      ]),
    );
  }

  Widget _seccion(String titulo, Color color, List<Widget> rows) => TmCard(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(titulo,style:GoogleFonts.syne(fontSize:15,fontWeight:FontWeight.w700,color:color)),
      const SizedBox(height:12),
      ...rows,
    ]));

  Widget _fila(TextEditingController ctrl, String label, String suffix) => Padding(
    padding:const EdgeInsets.only(bottom:10),
    child:Row(children:[
      Expanded(child:TmInput(controller:ctrl,label:label,icon:Icons.edit_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
      const SizedBox(width:8),
      Text(suffix,style:GoogleFonts.dmSans(fontSize:12,color:AppTheme.textSecondary)),
    ]));
}
