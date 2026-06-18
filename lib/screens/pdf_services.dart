import 'dart:convert';
import 'dart:typed_data'; // <-- Para manejar bytes en memoria
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// AHORA DEVUELVE Uint8List (Los datos crudos del PDF) EN LUGAR DE UN STRING
Future<Uint8List> generarReportePDF(
  BuildContext context, 
  String nombreViaje, 
  int totalOK, 
  List<String> faltantes, 
  String firmaJson,
  String comentariosAdicionales,
  String tipoFase,
) async {
  final pdf = pw.Document();
  final tieneFirma = firmaJson.trim().isNotEmpty && firmaJson != '[]';
  
  final String tituloReporte = tipoFase == 'ZARPE' ? 'AUTORIZACIÓN DE ZARPE' : tipoFase == 'DURANTE' ? 'REPORTE DE OPERACIÓN' : tipoFase == 'CIERRE' ? 'REPORTE FINAL Y CIERRE' : 'REPORTE DE INVENTARIO';

  pw.MemoryImage? logoImage;
  try {
    final ByteData bytesImg = await rootBundle.load('lib/img/Yate_main.png');
    logoImage = pw.MemoryImage(bytesImg.buffer.asUint8List());
  } catch (e) {
    logoImage = null;
  }

  final colorPrimario = PdfColor.fromHex('#0A2440');
  final colorAcento = PdfColor.fromHex('#00E5FF');
  final colorFondo = PdfColor.fromHex('#F8FAFC');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('YATE DIAMOND', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
                    pw.Text(tituloReporte, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700, letterSpacing: 2)),
                  ]
                ),
                if (logoImage != null) 
                  pw.Container(height: 60, width: 100, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
              ]
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: colorAcento, thickness: 2),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(color: colorFondo, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("Identificador de Viaje:", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text(nombreViaje, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text("Fecha de Reporte:", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text(DateTime.now().toString().substring(0, 16), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]),
                ]
              )
            ),
            pw.SizedBox(height: 30),

            pw.Text("RESULTADOS DE AUDITORÍA", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Row(children: [
                pw.Text("✓", style: pw.TextStyle(color: PdfColors.green800, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 10),
                pw.Text("ÍTEMS VERIFICADOS CORRECTAMENTE: $totalOK", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              ])
            ),
            pw.SizedBox(height: 15),

            if (faltantes.isNotEmpty) ...[
              pw.Text("INCIDENCIAS / FALTANTES DETECTADOS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(15), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: faltantes.map((item) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(item, style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)))).toList())
              ),
              pw.SizedBox(height: 20),
            ],

            if (comentariosAdicionales.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(15), decoration: pw.BoxDecoration(color: PdfColors.orange50, border: pw.Border.all(color: PdfColors.orange200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("COMENTARIOS Y OBSERVACIONES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange900, fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Text(comentariosAdicionales, style: const pw.TextStyle(fontSize: 11)),
                ])
              ),
            ],

            pw.Spacer(),

            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text("Firma de Autorización / Cierre:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("___________________________", style: pw.TextStyle(color: PdfColors.grey400)),
            ]),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 120, width: double.infinity,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed), color: colorFondo, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              alignment: pw.Alignment.center,
              child: tieneFirma ? _dibujarFirmaPdf(firmaJson) : pw.Text("Sin firma registrada", style: pw.TextStyle(color: PdfColors.grey600)),
            ),
          ],
        );
      },
    ),
  );

  // ¡MAGIA PARA CHROME! Devolvemos los bytes directo de la memoria.
  return await pdf.save();
}

pw.Widget _dibujarFirmaPdf(String firmaJson) {
  try {
    final List<dynamic> puntos = jsonDecode(firmaJson);
    return pw.CustomPaint(
      size: const PdfPoint(400, 120),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setColor(PdfColors.black); 
        canvas.setLineWidth(3.0); 
        for (int i = 0; i < puntos.length - 1; i++) {
          final p1 = puntos[i];
          final p2 = puntos[i + 1];
          if (p1 != null && p2 != null) {
            final double x1 = (p1['dx'] as num).toDouble();
            final double y1 = 180.0 - (p1['dy'] as num).toDouble();
            final double x2 = (p2['dx'] as num).toDouble();
            final double y2 = 180.0 - (p2['dy'] as num).toDouble();
            canvas.drawLine(x1, y1, x2, y2);
          }
        }
        canvas.strokePath();
      },
    );
  } catch (e) {
    return pw.Text("Error al renderizar firma", style: pw.TextStyle(color: PdfColors.red));
  }
}