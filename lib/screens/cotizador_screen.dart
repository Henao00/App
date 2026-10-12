import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/cotizacion.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';

const _filtros = [
  ('todos',    'Todos',    Icons.apps_rounded),
  ('poron',    'Porones',  Icons.grid_4x4_rounded),
  ('cemento',  'Cemento',  Icons.construction_rounded),
  ('arena',    'Arena',    Icons.terrain_rounded),
  ('varilla',  'Varillas', Icons.linear_scale_rounded),
  ('ladrillo', 'Ladrillo', Icons.view_module_rounded),
  ('pintura',  'Pintura',  Icons.format_paint_rounded),
  ('custom',   'Variable', Icons.tune_rounded),
];

class _MatDef {
  final String id, nombre, unidad, categoria;
  final IconData icon;
  final bool tieneVariante; // true = varilla (pide diámetro)
  final double Function(AppPrecios) getPrecio;
  const _MatDef({required this.id, required this.nombre, required this.unidad,
      required this.categoria, required this.icon,
      this.tieneVariante = false, required this.getPrecio});
}

List<_MatDef> _catalogo(AppPrecios p) => [
  _MatDef(id:'poron_m2',  nombre:'Porones m²',        unidad:'m²',    categoria:'poron',    icon:Icons.grid_4x4_rounded,     getPrecio:(_)=>p.precioM2),
  _MatDef(id:'poron_m3',  nombre:'Porones m³',         unidad:'m³',    categoria:'poron',    icon:Icons.view_in_ar_rounded,   getPrecio:(_)=>p.precioM3>0?p.precioM3:p.precioM2),
  _MatDef(id:'cemento',   nombre:'Cemento bolsa 50kg', unidad:'bolsa', categoria:'cemento',  icon:Icons.construction_rounded, getPrecio:(_)=>p.precioCemento),
  _MatDef(id:'arena',     nombre:'Arena',              unidad:'m³',    categoria:'arena',    icon:Icons.terrain_rounded,      getPrecio:(_)=>p.precioArena),
  _MatDef(id:'varilla',   nombre:'Varilla',            unidad:'ml',    categoria:'varilla',  icon:Icons.linear_scale_rounded, tieneVariante:true, getPrecio:(_)=>p.precioVarilla),
  _MatDef(id:'ladrillo',  nombre:'Ladrillo',           unidad:'und',   categoria:'ladrillo', icon:Icons.view_module_rounded,  getPrecio:(_)=>p.precioLadrillo),
  _MatDef(id:'bloque',    nombre:'Bloque',             unidad:'und',   categoria:'ladrillo', icon:Icons.dashboard_rounded,    getPrecio:(_)=>p.precioBloque),
  _MatDef(id:'pintura',   nombre:'Pintura',            unidad:'litro', categoria:'pintura',  icon:Icons.format_paint_rounded, getPrecio:(_)=>p.precioPintura),
  _MatDef(id:'stucco',    nombre:'Estuco',             unidad:'kg',    categoria:'pintura',  icon:Icons.brush_rounded,        getPrecio:(_)=>p.precioStucco),
];

// Diámetros comunes de varilla
const _diametros = ['3/8"', '1/2"', '5/8"', '3/4"', '1"', 'otro'];

/// `firstWhere` sin excepción: devuelve null si no hay coincidencia.
T? _firstOrNull<T>(Iterable<T> it) => it.isEmpty ? null : it.first;

class CotizadorScreen extends StatefulWidget {
  final AppPrecios precios;
  final VoidCallback onGuardado;
  final Cotizacion? prefill;
  final int prefillToken;
  const CotizadorScreen({
    super.key,
    required this.precios,
    required this.onGuardado,
    this.prefill,
    this.prefillToken = 0,
  });
  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final _storage = StorageService();
  final _uuid = const Uuid();

  final _clienteCtrl    = TextEditingController();
  final _obraCtrl       = TextEditingController();
  final _notasCtrl      = TextEditingController();
  final _cantCtrl       = TextEditingController();
  final _altCtrl        = TextEditingController();
  final _busquedaCtrl   = TextEditingController();
  final _varillaPrecioCtrl = TextEditingController();
  final _varillaDiamCtrl   = TextEditingController(); // para "otro"
  final _varNombreCtrl  = TextEditingController();
  final _varPrecioCtrl  = TextEditingController();
  final _varCantCtrl    = TextEditingController();

  final List<MaterialItem> _items = [];
  String  _filtro      = 'todos';
  String  _busqueda    = '';
  String? _selId;
  String? _selCustomId;
  String  _varUnidad   = 'und';
  String  _selDiametro = '3/8"'; // diámetro seleccionado para varilla
  bool    _carritoAbierto = false;

  @override
  void initState() {
    super.initState();
    _altCtrl.text = (widget.precios.alturaDefault * 100).toStringAsFixed(0);
    _varillaPrecioCtrl.text = widget.precios.precioVarilla.toStringAsFixed(0);
    if (widget.prefill != null) _cargarPrefill(widget.prefill!);
  }

  @override
  void didUpdateWidget(covariant CotizadorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefillToken != oldWidget.prefillToken && widget.prefill != null) {
      _cargarPrefill(widget.prefill!);
    }
  }

  void _cargarPrefill(Cotizacion c) {
    setState(() {
      _items
        ..clear()
        ..addAll(c.items);
      _clienteCtrl.text = c.cliente;
      _obraCtrl.text = c.obra;
      _notasCtrl.text = c.notas;
      _carritoAbierto = true;
      _selId = null;
      _selCustomId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showTmSnack(context, 'Cotización cargada para editar');
    });
  }

  @override
  void dispose() {
    for (final c in [_clienteCtrl,_obraCtrl,_notasCtrl,_cantCtrl,_altCtrl,_busquedaCtrl,
        _varillaPrecioCtrl,_varillaDiamCtrl,_varNombreCtrl,_varPrecioCtrl,_varCantCtrl]) c.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0.0, (s, i) => s + i.subtotal);

  void _snack(String msg) => showTmSnack(context, msg, error: true);

  // ── Agregar material/preset seleccionado ──────────────────
  void _agregarSeleccion() {
    final catalogo = _catalogo(widget.precios);

    if (_selCustomId != null) {
      final preset = _firstOrNull(widget.precios.customMateriales
          .where((m) => m.id == _selCustomId));
      if (preset == null) { _snack('Ese material ya no existe'); setState(()=>_selCustomId=null); return; }
      final cant = TmFormat.parseNum(_cantCtrl.text) ?? 0;
      if (cant <= 0) { _snack('Ingresa la cantidad'); return; }
      setState(() {
        _items.add(MaterialItem(id:_uuid.v4(), nombre:preset.nombre, categoria:'custom',
            cantidad:cant, precioUnitario:preset.precioUnitario, unidad:preset.unidad,
            subtotal:cant*preset.precioUnitario));
        _cantCtrl.clear(); _selCustomId = null; _carritoAbierto = true;
      });
      return;
    }

    final mat = _firstOrNull(catalogo.where((m) => m.id == _selId));
    if (mat == null) { _snack('Selecciona un material'); return; }
    final cant = TmFormat.parseNum(_cantCtrl.text) ?? 0;
    if (cant <= 0) { _snack('Ingresa la cantidad'); return; }

    if (_selId == 'varilla') {
      final diam   = _selDiametro == 'otro' ? _varillaDiamCtrl.text.trim() : _selDiametro;
      final precio = TmFormat.parseNum(_varillaPrecioCtrl.text) ?? widget.precios.precioVarilla;
      if (diam.isEmpty) { _snack('Ingresa el diámetro'); return; }
      if (precio <= 0)  { _snack('Ingresa el precio'); return; }
      setState(() {
        _items.add(MaterialItem(id:_uuid.v4(), nombre:'Varilla $diam',
            categoria:'varilla', cantidad:cant, precioUnitario:precio,
            unidad:'ml', subtotal:cant*precio));
        _cantCtrl.clear(); _selId = null; _carritoAbierto = true;
      });
      return;
    }

    if (_selId == 'poron_m2') {
      final alt    = (TmFormat.parseNum(_altCtrl.text) ?? 25) / 100;
      final precio = mat.getPrecio(widget.precios);
      final m3     = cant * alt;
      setState(() {
        _items.add(MaterialItem(id:_uuid.v4(),
            nombre:'Porones m² (grosor ${(alt*100).toStringAsFixed(0)} cm)',
            categoria:'poron', cantidad:cant, precioUnitario:precio, unidad:'m²', subtotal:cant*precio));
        if (widget.precios.precioM3 > 0)
          _items.add(MaterialItem(id:_uuid.v4(), nombre:'  └ Volumen m³ calculado',
              categoria:'poron', cantidad:m3, precioUnitario:widget.precios.precioM3,
              unidad:'m³', subtotal:m3*widget.precios.precioM3));
        _cantCtrl.clear(); _selId = null; _carritoAbierto = true;
      });
      return;
    }

    final precio = mat.getPrecio(widget.precios);
    setState(() {
      _items.add(MaterialItem(id:_uuid.v4(), nombre:mat.nombre, categoria:mat.categoria,
          cantidad:cant, precioUnitario:precio, unidad:mat.unidad, subtotal:cant*precio));
      _cantCtrl.clear(); _selId = null; _carritoAbierto = true;
    });
  }

  // ── Agregar material variable manual ──────────────────────
  void _agregarVariable() {
    final nombre = _varNombreCtrl.text.trim();
    final precio = TmFormat.parseNum(_varPrecioCtrl.text) ?? 0;
    final cant   = TmFormat.parseNum(_varCantCtrl.text) ?? 0;
    if (nombre.isEmpty || precio <= 0 || cant <= 0) {
      _snack('Completa nombre, precio y cantidad');
      return;
    }
    setState(() {
      _items.add(MaterialItem(id:_uuid.v4(), nombre:nombre, categoria:'custom',
          cantidad:cant, precioUnitario:precio, unidad:_varUnidad, subtotal:cant*precio));
      _varNombreCtrl.clear(); _varPrecioCtrl.clear(); _varCantCtrl.clear();
      _carritoAbierto = true;
    });
  }

  Future<void> _guardar() async {
    if (_items.isEmpty) { _snack('Agrega al menos un material'); return; }
    final numero = await _storage.nextNumero();
    await _storage.saveCotizacion(Cotizacion(
      id:_uuid.v4(), fecha:DateTime.now(), numero:numero,
      cliente:_clienteCtrl.text.trim(), obra:_obraCtrl.text.trim(),
      items:List.from(_items), total:_total, notas:_notasCtrl.text.trim(),
    ));
    await _storage.commitNumero(numero);
    setState(() { _items.clear(); _selId=null; _selCustomId=null; _carritoAbierto=false; });
    _clienteCtrl.clear(); _obraCtrl.clear(); _notasCtrl.clear();
    widget.onGuardado();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo   = _catalogo(widget.precios);
    final ql = _busqueda.trim().toLowerCase();
    final visibles   = catalogo.where((m) =>
        (_filtro == 'todos' || m.categoria == _filtro) &&
        (ql.isEmpty || m.nombre.toLowerCase().contains(ql))).toList();
    final customsVis = ((_filtro == 'todos' || _filtro == 'custom')
            ? widget.precios.customMateriales
            : <MaterialPreset>[])
        .where((p) => ql.isEmpty || p.nombre.toLowerCase().contains(ql))
        .toList();

    return Column(children: [
      // Cliente / Obra
      Container(color:AppTheme.surface, padding:const EdgeInsets.fromLTRB(12,10,12,10),
        child: Row(children: [
          Expanded(child: TmInput(controller:_clienteCtrl, label:'Cliente', icon:Icons.person_outline_rounded)),
          const SizedBox(width:8),
          Expanded(child: TmInput(controller:_obraCtrl, label:'Obra', icon:Icons.location_on_outlined)),
        ]),
      ),

      // Filtros
      Container(color:AppTheme.surface, height:42,
        child: ListView(scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
          children: _filtros.map((f) {
            final (id, label, icon) = f;
            final active = _filtro == id;
            final col = AppTheme.categoryColor(id);
            return GestureDetector(
              onTap: () => setState(() { _filtro=id; _selId=null; _selCustomId=null; }),
              child: AnimatedContainer(duration:const Duration(milliseconds:150),
                margin:const EdgeInsets.only(right:8),
                padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),
                decoration:BoxDecoration(color:active?col:AppTheme.bg, borderRadius:BorderRadius.circular(20),
                    border:Border.all(color:active?col:AppTheme.border)),
                child: Row(mainAxisSize:MainAxisSize.min, children:[
                  Icon(icon, size:13, color:active?Colors.white:AppTheme.textSecondary),
                  const SizedBox(width:4),
                  Text(label, style:GoogleFonts.dmSans(fontSize:12, fontWeight:FontWeight.w600,
                      color:active?Colors.white:AppTheme.textSecondary)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      const Divider(height:1, color:AppTheme.border),

      // Búsqueda
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: TmInput(
          controller: _busquedaCtrl,
          label: 'Buscar material',
          icon: Icons.search_rounded,
          suffixIcon: _busqueda.isEmpty ? null : Icons.close_rounded,
          onSuffixTap: () => setState(() { _busquedaCtrl.clear(); _busqueda=''; }),
          onChanged: (v) => setState(() => _busqueda = v),
          textInputAction: TextInputAction.search,
        ),
      ),

      // Catálogo
      Expanded(
        child: ListView(padding:const EdgeInsets.fromLTRB(12,10,12,10), children:[
          if (_selId != null || _selCustomId != null) ...[
            _cantidadForm(), const SizedBox(height:8),
          ],
          if (visibles.isNotEmpty) ...[
            _secLabel('Materiales disponibles'),
            ...visibles.map((m) => _matTile(m)),
          ],
          if (customsVis.isNotEmpty) ...[
            _secLabel('Mis materiales guardados'),
            ...customsVis.map((p) => _presetTile(p)),
          ],
          if (_filtro == 'todos' || _filtro == 'custom') ...[
            _secLabel('Material variable (manual)'),
            _variableForm(),
          ],
          if (visibles.isEmpty && customsVis.isEmpty && ql.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: TmEmptyState(icon:'🔍', title:'Sin resultados', message:'No encontramos materiales con ese nombre.'),
            ),
          const SizedBox(height:16),
        ]),
      ),

      _carritoBar(),
    ]);
  }

  Widget _matTile(_MatDef mat) {
    final sel = _selId == mat.id;
    final col = AppTheme.categoryColor(mat.categoria);
    return GestureDetector(
      onTap: () => setState(() { _selId = sel ? null : mat.id; _selCustomId=null; _cantCtrl.clear(); }),
      child: AnimatedContainer(duration:const Duration(milliseconds:150),
        margin:const EdgeInsets.only(bottom:8),
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:11),
        decoration:BoxDecoration(color:sel?col.withValues(alpha:0.1):AppTheme.surface,
            borderRadius:BorderRadius.circular(12),
            border:Border.all(color:sel?col:AppTheme.border, width:sel?2:1)),
        child: Row(children:[
          Container(width:38,height:38,
            decoration:BoxDecoration(color:col.withValues(alpha:0.15),borderRadius:BorderRadius.circular(10)),
            child:Icon(mat.icon,color:col,size:19)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(mat.nombre,style:GoogleFonts.dmSans(fontSize:13,fontWeight:FontWeight.w600,
                color:sel?col:AppTheme.textPrimary)),
            Text(mat.tieneVariante
                ? 'Precio variable por diámetro / ml'
                : '${TmFormat.cop(mat.getPrecio(widget.precios))} / ${mat.unidad}',
                style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
          ])),
          Icon(sel?Icons.check_circle_rounded:Icons.add_circle_outline_rounded,
              color:sel?col:AppTheme.textSecondary,size:22),
        ]),
      ),
    );
  }

  Widget _presetTile(MaterialPreset preset) {
    final sel = _selCustomId == preset.id;
    final col = AppTheme.categoryColor('custom');
    return GestureDetector(
      onTap: () => setState(() { _selCustomId=sel?null:preset.id; _selId=null; _cantCtrl.clear(); }),
      child: AnimatedContainer(duration:const Duration(milliseconds:150),
        margin:const EdgeInsets.only(bottom:8),
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:11),
        decoration:BoxDecoration(color:sel?col.withValues(alpha:0.1):AppTheme.surface,
            borderRadius:BorderRadius.circular(12),
            border:Border.all(color:sel?col:AppTheme.border,width:sel?2:1)),
        child:Row(children:[
          Container(width:38,height:38,
            decoration:BoxDecoration(color:col.withValues(alpha:0.15),borderRadius:BorderRadius.circular(10)),
            child:Icon(Icons.tune_rounded,color:col,size:19)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(preset.nombre,style:GoogleFonts.dmSans(fontSize:13,fontWeight:FontWeight.w600,
                color:sel?col:AppTheme.textPrimary)),
            Text('${TmFormat.cop(preset.precioUnitario)} / ${preset.unidad}',
                style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
          ])),
          Icon(sel?Icons.check_circle_rounded:Icons.add_circle_outline_rounded,
              color:sel?col:AppTheme.textSecondary,size:22),
        ]),
      ),
    );
  }

  Widget _cantidadForm() {
    final catalogo = _catalogo(widget.precios);
    String nombre = '';
    Color col = AppTheme.primary;
    if (_selId != null) {
      final mat = _firstOrNull(catalogo.where((m) => m.id == _selId));
      nombre = mat?.nombre ?? '';
      col = AppTheme.categoryColor(mat?.categoria ?? 'custom');
    } else if (_selCustomId != null) {
      final preset = _firstOrNull(widget.precios.customMateriales.where((m) => m.id == _selCustomId));
      nombre = preset?.nombre ?? '';
      col = AppTheme.categoryColor('custom');
    }

    return Container(
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:col.withValues(alpha:0.08),
          borderRadius:BorderRadius.circular(14),
          border:Border.all(color:col.withValues(alpha:0.5),width:1.5)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Icon(Icons.shopping_cart_rounded,color:col,size:16),
          const SizedBox(width:6),
          Expanded(child:Text('Cantidad para: $nombre',
              style:GoogleFonts.dmSans(fontSize:13,fontWeight:FontWeight.w600,color:col))),
          GestureDetector(onTap:()=>setState((){_selId=null;_selCustomId=null;}),
              child:Icon(Icons.close_rounded,color:AppTheme.textSecondary,size:18)),
        ]),
        const SizedBox(height:10),

        // ── Porón m² ──
        if (_selId == 'poron_m2') ...[
          Row(children:[
            Expanded(child:TmInput(controller:_cantCtrl,label:'Área m²',icon:Icons.square_foot_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width:8),
            Expanded(child:TmInput(controller:_altCtrl,label:'Grosor cm',icon:Icons.height_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height:8),
          Wrap(spacing:6, children:[20,25,30,35,40].map((h)=>GestureDetector(
            onTap:()=>setState(()=>_altCtrl.text=h.toString()),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
              decoration:BoxDecoration(color:_altCtrl.text==h.toString()?col:AppTheme.bg,
                  borderRadius:BorderRadius.circular(16),
                  border:Border.all(color:_altCtrl.text==h.toString()?col:AppTheme.border)),
              child:Text('$h cm',style:GoogleFonts.dmSans(fontSize:11,
                  color:_altCtrl.text==h.toString()?Colors.white:AppTheme.textSecondary))),
          )).toList()),
        ]

        // ── Varilla con diámetro ──
        else if (_selId == 'varilla') ...[
          Text('Diámetro:', style:GoogleFonts.dmSans(fontSize:12,color:AppTheme.textSecondary)),
          const SizedBox(height:6),
          Wrap(spacing:6, children:_diametros.map((d)=>GestureDetector(
            onTap:()=>setState(()=>_selDiametro=d),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
              margin:const EdgeInsets.only(bottom:6),
              decoration:BoxDecoration(
                  color:_selDiametro==d?col:AppTheme.bg,
                  borderRadius:BorderRadius.circular(16),
                  border:Border.all(color:_selDiametro==d?col:AppTheme.border)),
              child:Text(d,style:GoogleFonts.dmSans(fontSize:12,fontWeight:FontWeight.w600,
                  color:_selDiametro==d?Colors.white:AppTheme.textSecondary))),
          )).toList()),
          if (_selDiametro == 'otro') ...[
            const SizedBox(height:8),
            TmInput(controller:_varillaDiamCtrl, label:'Diámetro (ej: 5/8")', icon:Icons.straighten_rounded),
          ],
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TmInput(controller:_cantCtrl, label:'Cantidad ml', icon:Icons.numbers_rounded, keyboardType:const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width:8),
            Expanded(child:TmInput(controller:_varillaPrecioCtrl, label:'Precio/ml \$', icon:Icons.attach_money_rounded, keyboardType:const TextInputType.numberWithOptions(decimal: true))),
          ]),
        ]

        // ── Resto ──
        else
          TmInput(controller:_cantCtrl,label:'Cantidad',icon:Icons.numbers_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true)),

        const SizedBox(height:12),
        SizedBox(width:double.infinity,
          child:ElevatedButton.icon(onPressed:_agregarSeleccion,
            icon:const Icon(Icons.add_shopping_cart_rounded,size:18),
            label:Text('Agregar a la lista',style:GoogleFonts.dmSans(fontWeight:FontWeight.w700,fontSize:14)),
            style:ElevatedButton.styleFrom(backgroundColor:col,foregroundColor:Colors.white,
                padding:const EdgeInsets.symmetric(vertical:14),
                shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),elevation:0))),
      ]),
    );
  }

  Widget _variableForm() => Container(
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(12),
        border:Border.all(color:AppTheme.border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      TmInput(controller:_varNombreCtrl,label:'Nombre del material',icon:Icons.label_outline_rounded),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:TmInput(controller:_varPrecioCtrl,label:'Precio \$',icon:Icons.attach_money_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
        const SizedBox(width:8),
        Expanded(child:TmInput(controller:_varCantCtrl,label:'Cantidad',icon:Icons.numbers_rounded,keyboardType:const TextInputType.numberWithOptions(decimal: true))),
      ]),
      const SizedBox(height:8),
      Wrap(spacing:6,children:['und','m²','m³','ml','kg','litro','bolsa','rollo'].map((u)=>GestureDetector(
        onTap:()=>setState(()=>_varUnidad=u),
        child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
          decoration:BoxDecoration(color:_varUnidad==u?AppTheme.categoryColor('custom'):AppTheme.bg,
              borderRadius:BorderRadius.circular(16),
              border:Border.all(color:_varUnidad==u?AppTheme.categoryColor('custom'):AppTheme.border)),
          child:Text(u,style:GoogleFonts.dmSans(fontSize:11,
              color:_varUnidad==u?Colors.white:AppTheme.textSecondary))),
      )).toList()),
      const SizedBox(height:10),
      SizedBox(width:double.infinity,
        child:ElevatedButton.icon(onPressed:_agregarVariable,
          icon:const Icon(Icons.add_shopping_cart_rounded,size:18),
          label:Text('Agregar variable',style:GoogleFonts.dmSans(fontWeight:FontWeight.w700,fontSize:14)),
          style:ElevatedButton.styleFrom(backgroundColor:AppTheme.categoryColor('custom'),foregroundColor:Colors.white,
              padding:const EdgeInsets.symmetric(vertical:14),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),elevation:0))),
    ]),
  );

  Widget _carritoBar() {
    if (_items.isEmpty) {
      return Container(
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),
        decoration:const BoxDecoration(color:AppTheme.surface,border:Border(top:BorderSide(color:AppTheme.border))),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          const Icon(Icons.shopping_cart_outlined,color:AppTheme.textSecondary,size:18),
          const SizedBox(width:8),
          Text('Lista vacía — toca un material para agregar',
              style:GoogleFonts.dmSans(fontSize:13,color:AppTheme.textSecondary)),
        ]),
      );
    }
    return Container(
      decoration:const BoxDecoration(color:AppTheme.surface,
          border:Border(top:BorderSide(color:AppTheme.border,width:1.5))),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        GestureDetector(
          onTap:()=>setState(()=>_carritoAbierto=!_carritoAbierto),
          child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
            child:Row(children:[
              const Icon(Icons.shopping_cart_rounded,color:AppTheme.primary,size:18),
              const SizedBox(width:8),
              Text('${_items.length} items en la lista',
                  style:GoogleFonts.dmSans(fontSize:13,fontWeight:FontWeight.w600,color:AppTheme.textPrimary)),
              const Spacer(),
              Text(TmFormat.cop(_total),
                  style:GoogleFonts.syne(fontSize:16,fontWeight:FontWeight.w800,color:AppTheme.primary)),
              const SizedBox(width:8),
              Icon(_carritoAbierto?Icons.keyboard_arrow_down_rounded:Icons.keyboard_arrow_up_rounded,
                  color:AppTheme.textSecondary),
            ]),
          ),
        ),
        if (_carritoAbierto) ...[
          const Divider(height:1,color:AppTheme.border),
          ConstrainedBox(constraints:const BoxConstraints(maxHeight:220),
            child:ListView.builder(shrinkWrap:true,
              padding:const EdgeInsets.fromLTRB(12,6,12,0),
              itemCount:_items.length,
              itemBuilder:(_,i){
                final item=_items[i];
                final col=AppTheme.categoryColor(item.categoria);
                return Container(margin:const EdgeInsets.only(bottom:6),
                  padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),
                  decoration:BoxDecoration(color:AppTheme.bg,borderRadius:BorderRadius.circular(10),
                      border:Border(left:BorderSide(color:col,width:3))),
                  child:Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(item.nombre,style:GoogleFonts.dmSans(fontSize:12,fontWeight:FontWeight.w600,
                          color:AppTheme.textPrimary),overflow:TextOverflow.ellipsis),
                      Text('${TmFormat.qty(item.cantidad)} ${item.unidad}  ×  ${TmFormat.cop(item.precioUnitario)}',
                          style:GoogleFonts.dmSans(fontSize:11,color:AppTheme.textSecondary)),
                    ])),
                    Text(TmFormat.cop(item.subtotal),
                        style:GoogleFonts.syne(fontSize:13,color:AppTheme.primary,fontWeight:FontWeight.w700)),
                    const SizedBox(width:4),
                    GestureDetector(onTap:()=>setState(()=>_items.removeAt(i)),
                        child:const Icon(Icons.close_rounded,size:16,color:AppTheme.danger)),
                  ]),
                );
              }),
          ),
          const Divider(height:1,color:AppTheme.border),
          Padding(padding:const EdgeInsets.fromLTRB(12,8,12,14),
            child:Column(children:[
              TmInput(controller:_notasCtrl,label:'Notas (opcional)',icon:Icons.note_alt_outlined),
              const SizedBox(height:10),
              SizedBox(width:double.infinity,
                child:ElevatedButton.icon(onPressed:_guardar,
                  icon:const Icon(Icons.save_rounded,size:18),
                  label:Text('Guardar cotización — ${TmFormat.cop(_total)}',
                      style:GoogleFonts.dmSans(fontWeight:FontWeight.w700,fontSize:15)),
                  style:ElevatedButton.styleFrom(backgroundColor:AppTheme.primary,foregroundColor:Colors.black,
                      padding:const EdgeInsets.symmetric(vertical:16),
                      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),elevation:0))),
            ])),
        ],
      ]),
    );
  }

  Widget _secLabel(String label) => Padding(
    padding:const EdgeInsets.only(bottom:8,top:6),
    child:Text(label,style:GoogleFonts.syne(fontSize:12,fontWeight:FontWeight.w700,color:AppTheme.textSecondary)));
}
