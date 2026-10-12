import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cotizacion.dart';
import '../models/empresa.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Generación y distribución de cotizaciones en PDF.
///
/// Reutiliza el diseño existente y añade la marca de la empresa (opcional) y
/// el envío por el share sheet del sistema (WhatsApp, correo, etc.).
class PdfService {
  static Future<pw.MemoryImage?> loadLogo() async {
    try {
      final data = await rootBundle.load('assets/icon/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static PdfColor _catCol(String cat) =>
      PdfColor.fromHex(AppTheme.categoryHex[cat] ?? '11CDEF');

  static String get _fileName => 'T&M';

  static Future<Uint8List> buildCotizacion(
    Cotizacion c, {
    bool mostrarPrecios = true,
    Empresa? empresa,
    pw.MemoryImage? logo,
  }) async {
    final pdf = pw.Document();
    final accent = PdfColor.fromHex('F5A623');
    final dark = PdfColor.fromHex('0F1117');
    final surface = PdfColor.fromHex('1A1D27');
    final gray = PdfColor.fromHex('9AA0B8');
    final light = PdfColor.fromHex('F4F4F4');
    final hasEmpresa = empresa != null && !empresa.isEmpty;
    final marca = hasEmpresa ? empresa.nombre : 'T&M';
    final allItems = List<MaterialItem>.from(c.items);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: pw.BoxDecoration(color: dark, borderRadius: pw.BorderRadius.circular(12)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(children: [
                        if (logo != null) ...[
                          pw.Image(logo, width: 34, height: 34),
                          pw.SizedBox(width: 10),
                        ],
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(marca, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
                          pw.SizedBox(height: 2),
                          pw.Text(hasEmpresa ? 'Cotización de materiales' : 'Construcción · Materiales',
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                          if (hasEmpresa && empresa.nit.isNotEmpty)
                            pw.Text('NIT: ${empresa.nit}', style: pw.TextStyle(fontSize: 9, color: gray)),
                          if (hasEmpresa && (empresa.telefono.isNotEmpty || empresa.email.isNotEmpty))
                            pw.Text(
                              [if (empresa.telefono.isNotEmpty) empresa.telefono, if (empresa.email.isNotEmpty) empresa.email].join(' · '),
                              style: pw.TextStyle(fontSize: 9, color: gray),
                            ),
                          if (hasEmpresa && empresa.direccion.isNotEmpty)
                            pw.Text([empresa.direccion, empresa.ciudad].where((e) => e.isNotEmpty).join(', '),
                                style: pw.TextStyle(fontSize: 9, color: gray)),
                          if (c.cliente.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Text('Cliente: ${c.cliente}', style: pw.TextStyle(fontSize: 11, color: PdfColors.white)),
                          ],
                          if (c.obra.isNotEmpty)
                            pw.Text('Obra: ${c.obra}', style: pw.TextStyle(fontSize: 11, color: gray)),
                        ]),
                      ]),
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text(mostrarPrecios ? 'COTIZACIÓN' : 'LISTA DE MATERIALES',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent)),
                        pw.Text('#${c.numero.toString().padLeft(4, '0')}',
                            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 4),
                        pw.Text(TmFormat.date(c.fecha), style: pw.TextStyle(fontSize: 11, color: gray)),
                        pw.SizedBox(height: 4),
                        pw.Text('${allItems.length} item(s)', style: pw.TextStyle(fontSize: 10, color: gray)),
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('DETALLE DE MATERIALES',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: gray, letterSpacing: 1.5)),
                pw.SizedBox(height: 8),
                pw.Container(
                  decoration: pw.BoxDecoration(color: surface),
                  child: pw.Row(children: mostrarPrecios
                      ? [
                          _hFlex('Descripción', 3.5),
                          _hFlex('Cantidad', 1.5),
                          _hFlex('Precio Unit.', 1.8),
                          _hFlex('Subtotal', 2.0),
                        ]
                      : [
                          _hFlex('Descripción', 5.0),
                          _hFlex('Cantidad', 2.0),
                        ]),
                ),
              ])
            : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('$marca · #${c.numero.toString().padLeft(4, '0')}${c.cliente.isNotEmpty ? ' · ${c.cliente}' : ''}',
                      style: pw.TextStyle(fontSize: 10, color: gray)),
                  pw.Text('Página ${ctx.pageNumber}', style: pw.TextStyle(fontSize: 10, color: gray)),
                ]),
                pw.SizedBox(height: 6),
                pw.Container(
                  decoration: pw.BoxDecoration(color: surface),
                  child: pw.Row(children: mostrarPrecios
                      ? [_hFlex('Descripción', 3.5), _hFlex('Cantidad', 1.5), _hFlex('Precio Unit.', 1.8), _hFlex('Subtotal', 2.0)]
                      : [_hFlex('Descripción', 5.0), _hFlex('Cantidad', 2.0)]),
                ),
              ]),

        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              mostrarPrecios
                  ? 'Cotización $_fileName · Precios en pesos colombianos (COP)'
                  : 'Lista $_fileName · Solo referencia de materiales',
              style: pw.TextStyle(fontSize: 8, color: gray),
            ),
            pw.Text('Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: gray)),
          ],
        ),

        build: (ctx) {
          final rows = <pw.Widget>[];

          for (var i = 0; i < allItems.length; i++) {
            final item = allItems[i];
            final bg = i % 2 == 0 ? PdfColors.white : light;
            final col = _catCol(item.categoria);
            final cantStr = '${TmFormat.qty(item.cantidad)} ${item.unidad}';

            rows.add(
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: bg,
                  border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Row(
                  children: mostrarPrecios
                      ? [
                          _itemNombre(item.nombre, col, 3.5),
                          _itemCell(cantStr, 1.5),
                          _itemCell(TmFormat.cop(item.precioUnitario), 1.8),
                          _itemCell(TmFormat.cop(item.subtotal), 2.0, bold: true),
                        ]
                      : [
                          _itemNombre(item.nombre, col, 5.0),
                          _itemCell(cantStr, 2.0),
                        ],
                ),
              ),
            );
          }

          if (mostrarPrecios) {
            rows.add(pw.SizedBox(height: 0));
            rows.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(8),
                    bottomRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL A PAGAR',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: dark)),
                    pw.Text(TmFormat.cop(c.total),
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: dark)),
                  ],
                ),
              ),
            );
          }

          if (c.notas.isNotEmpty) {
            rows.add(pw.SizedBox(height: 16));
            rows.add(pw.Text('NOTAS',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: gray, letterSpacing: 1.5)));
            rows.add(pw.SizedBox(height: 6));
            rows.add(pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('DDDDDD')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(c.notas, style: const pw.TextStyle(fontSize: 11)),
            ));
          }

          return rows;
        },
      ),
    );

    return pdf.save();
  }

  /// Abre el diálogo de impresión del sistema.
  static Future<void> printCotizacion(
    Cotizacion c, {
    bool mostrarPrecios = true,
    Empresa? empresa,
  }) async {
    final logo = await loadLogo();
    await Printing.layoutPdf(
      onLayout: (_) => buildCotizacion(c, mostrarPrecios: mostrarPrecios, empresa: empresa, logo: logo),
      name: 'TM_${mostrarPrecios ? "Cotizacion" : "Lista"}_${c.numero.toString().padLeft(4, '0')}.pdf',
    );
  }

  /// Comparte el PDF por el share sheet (WhatsApp, correo, etc.).
  static Future<void> shareCotizacion(
    Cotizacion c, {
    bool mostrarPrecios = true,
    Empresa? empresa,
  }) async {
    final logo = await loadLogo();
    final bytes = await buildCotizacion(c, mostrarPrecios: mostrarPrecios, empresa: empresa, logo: logo);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'TM_${mostrarPrecios ? "Cotizacion" : "Lista"}_${c.numero.toString().padLeft(4, '0')}.pdf',
      subject: 'Cotización #${c.numero.toString().padLeft(4, '0')}',
    );
  }

  static pw.Widget _hFlex(String t, double flex) => pw.Expanded(
    flex: (flex * 10).toInt(),
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    ),
  );

  static pw.Widget _itemNombre(String nombre, PdfColor col, double flex) => pw.Expanded(
    flex: (flex * 10).toInt(),
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: pw.Row(children: [
        pw.Container(width: 3, height: 14,
            decoration: pw.BoxDecoration(color: col, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 6),
        pw.Expanded(child: pw.Text(nombre, style: const pw.TextStyle(fontSize: 11))),
      ]),
    ),
  );

  static pw.Widget _itemCell(String t, double flex, {bool bold = false}) => pw.Expanded(
    flex: (flex * 10).toInt(),
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: pw.Text(t, style: pw.TextStyle(
          fontSize: 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black)),
    ),
  );
}
