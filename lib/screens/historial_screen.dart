import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/cotizacion.dart';
import '../models/empresa.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';

class HistorialScreen extends StatefulWidget {
  final Empresa empresa;
  final ValueChanged<Cotizacion> onDuplicar;
  const HistorialScreen({super.key, required this.empresa, required this.onDuplicar});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _storage = StorageService();
  final _busquedaCtrl = TextEditingController();
  List<Cotizacion> _all = [];
  String _filtroMes = 'Todas';
  String _busqueda = '';
  bool _ordenDesc = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _storage.loadCotizaciones();
    if (!mounted) return;
    setState(() => _all = list);
  }

  List<String> get _meses {
    final s = <String>{};
    for (final c in _all) {
      s.add(TmFormat.monthYear(c.fecha));
    }
    return ['Todas', ...s.toList()];
  }

  List<Cotizacion> get _filtered {
    final q = _busqueda.trim().toLowerCase();
    final list = _all.where((c) {
      final okMes = _filtroMes == 'Todas' || TmFormat.monthYear(c.fecha) == _filtroMes;
      if (!okMes) return false;
      if (q.isEmpty) return true;
      return c.cliente.toLowerCase().contains(q) ||
          c.obra.toLowerCase().contains(q) ||
          c.notas.toLowerCase().contains(q) ||
          c.numero.toString().contains(q) ||
          c.items.any((i) => i.nombre.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => _ordenDesc ? b.fecha.compareTo(a.fecha) : a.fecha.compareTo(b.fecha));
    return list;
  }

  Future<void> _eliminar(Cotizacion c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar cotización',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar cotización #${c.numero}? Esta acción no se puede deshacer.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) {
      await _storage.deleteCotizacion(c.id);
      await _load();
    }
  }

  void _verDetalle(Cotizacion c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _DetalleSheet(
        c: c,
        empresa: widget.empresa,
        onDuplicar: widget.onDuplicar,
        onEstadoChange: (nuevo) async {
          await _storage.updateCotizacion(c.copyWith(estado: nuevo));
          await _load();
        },
      ),
    );
  }

  Future<void> _exportCsv() async {
    final list = _filtered;
    if (list.isEmpty) { showTmSnack(context, 'No hay cotizaciones para exportar', error: true); return; }
    final sb = StringBuffer('Numero,Fecha,Cliente,Obra,Estado,Items,Total\n');
    for (final c in list) {
      String esc(String v) => '"${v.replaceAll('"', '""')}"';
      sb.writeln([
        c.numero,
        TmFormat.date(c.fecha),
        esc(c.cliente),
        esc(c.obra),
        c.estado,
        c.items.length,
        c.total.toStringAsFixed(0),
      ].join(','));
    }
    try {
      final f = File('${Directory.systemTemp.path}/T&M_historial.csv');
      await f.writeAsString(sb.toString());
      await Share.shareXFiles([XFile(f.path)], subject: 'Historial T&M');
    } catch (_) {
      if (mounted) showTmSnack(context, 'No se pudo exportar el CSV', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // ── BÚSQUEDA + ORDEN + EXPORT ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TmInput(
                controller: _busquedaCtrl,
                label: 'Buscar cliente, obra o #',
                icon: Icons.search_rounded,
                suffixIcon: _busqueda.isEmpty ? null : Icons.close_rounded,
                onSuffixTap: () => setState(() { _busquedaCtrl.clear(); _busqueda = ''; }),
                onChanged: (v) => setState(() => _busqueda = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: _ordenDesc ? 'Más recientes primero' : 'Más antiguas primero',
              onPressed: () => setState(() => _ordenDesc = !_ordenDesc),
              icon: Icon(_ordenDesc ? Icons.sort_rounded : Icons.sort_rounded,
                  color: AppTheme.primary),
            ),
            IconButton(
              tooltip: 'Exportar CSV',
              onPressed: _exportCsv,
              icon: const Icon(Icons.ios_share_rounded, color: AppTheme.textSecondary),
            ),
          ]),
        ),

        // ── FILTROS POR MES ───────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _meses.length,
            itemBuilder: (_, i) {
              final m = _meses[i];
              final active = m == _filtroMes;
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _filtroMes = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
                    ),
                    child: Text(
                      m,
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── LISTA ─────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? TmEmptyState(
                  icon: '📭',
                  title: 'Sin cotizaciones',
                  message: _busqueda.isNotEmpty
                      ? 'No hay resultados para tu búsqueda.'
                      : 'Crea tu primera cotización en la pestaña Cotizar.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _CotizacionTile(
                    c: filtered[i],
                    onTap: () => _verDetalle(filtered[i]),
                    onDelete: () => _eliminar(filtered[i]),
                    onDuplicar: () => widget.onDuplicar(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── TILE ─────────────────────────────────────────────────────────────────────
class _CotizacionTile extends StatelessWidget {
  final Cotizacion c;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicar;

  const _CotizacionTile({
    required this.c,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicar,
  });

  static Color _estadoColor(String e) => switch (e) {
        EstadoCotizacion.enviada => const Color(0xFF5E72E4),
        EstadoCotizacion.aceptada => AppTheme.success,
        EstadoCotizacion.rechazada => AppTheme.danger,
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Cotización #${c.numero}',
                          style: GoogleFonts.syne(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      TmBadge(label: EstadoCotizacion.label(c.estado), color: _estadoColor(c.estado)),
                    ],
                  ),
                  if (c.cliente.isNotEmpty || c.obra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [if (c.cliente.isNotEmpty) c.cliente, if (c.obra.isNotEmpty) c.obra].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    TmFormat.cop(c.total),
                    style: GoogleFonts.syne(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.items.length} item(s)  ·  ${TmFormat.shortDate(c.fecha)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Duplicar',
                  onPressed: onDuplicar,
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 20),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DETALLE BOTTOM SHEET ─────────────────────────────────────────────────────
class _DetalleSheet extends StatefulWidget {
  final Cotizacion c;
  final Empresa empresa;
  final ValueChanged<Cotizacion> onDuplicar;
  final ValueChanged<String> onEstadoChange;

  const _DetalleSheet({
    required this.c,
    required this.empresa,
    required this.onDuplicar,
    required this.onEstadoChange,
  });

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  late String _estado;
  bool _compartiendo = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.c.estado;
  }

  Future<void> _compartir() async {
    setState(() => _compartiendo = true);
    try {
      await PdfService.shareCotizacion(widget.c, empresa: widget.empresa);
    } catch (_) {
      if (mounted) showTmSnack(context, 'No se pudo compartir el PDF', error: true);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            ),

            Text('Cotización #${c.numero}',
                style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(TmFormat.dateTime(c.fecha),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            if (c.cliente.isNotEmpty || c.obra.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (c.cliente.isNotEmpty) Text('Cliente: ${c.cliente}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              if (c.obra.isNotEmpty) Text('Obra: ${c.obra}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 16),

            // ── Estado de seguimiento ─────────────────────
            Text('Estado',
                style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: EstadoCotizacion.todos.map((e) {
              final active = e == _estado;
              final color = _CotizacionTile._estadoColor(e);
              return GestureDetector(
                onTap: () {
                  setState(() => _estado = e);
                  widget.onEstadoChange(e);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? color.withValues(alpha: 0.18) : AppTheme.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? color : AppTheme.border),
                  ),
                  child: Text(EstadoCotizacion.label(e),
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? color : AppTheme.textSecondary)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),

            // ── Detalle de materiales (el arreglo clave) ──
            Text('Materiales',
                style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TmCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  if (c.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin detalle de materiales (cotización antigua).',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    )
                  else
                    ...c.items.map((item) {
                      final col = AppTheme.categoryColor(item.categoria);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Container(width: 3, height: 28, decoration: BoxDecoration(
                              color: col, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.nombre,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                              Text('${TmFormat.qty(item.cantidad)} ${item.unidad}  ×  ${TmFormat.cop(item.precioUnitario)}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ]),
                          ),
                          Text(TmFormat.cop(item.subtotal),
                              style: GoogleFonts.syne(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ]),
                      );
                    }),
                  const Divider(color: AppTheme.border, height: 20),
                  ResultRow(label: 'TOTAL', value: TmFormat.cop(c.total), highlight: true),
                ],
              ),
            ),

            if (c.notas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notas',
                  style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Text(c.notas, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ],

            const SizedBox(height: 20),
            TmButton(
              label: 'Compartir (WhatsApp, PDF)',
              icon: Icons.share_rounded,
              onPressed: _compartiendo ? null : _compartir,
              loading: _compartiendo,
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            TmButton(
              label: 'PDF con precios',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFF5E72E4),
              onPressed: () => PdfService.printCotizacion(c, empresa: widget.empresa),
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            TmButton(
              label: 'PDF solo lista de materiales',
              icon: Icons.list_alt_rounded,
              color: AppTheme.surface2,
              onPressed: () => PdfService.printCotizacion(c, mostrarPrecios: false, empresa: widget.empresa),
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            TmButton(
              label: 'Duplicar cotización',
              icon: Icons.copy_rounded,
              color: AppTheme.success,
              onPressed: () {
                Navigator.pop(context);
                widget.onDuplicar(c);
              },
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            TmButton(
              label: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
