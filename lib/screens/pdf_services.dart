import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generarReportePDF(BuildContext context, String nombreViaje, int totalOK, List<String> faltantes, String firmaJson) async {
  final pdf = pw.Document();
  final tieneFirma = firmaJson.trim().isNotEmpty;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "REPORTE OPERATIVO DIAMOND",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text("Viaje: $nombreViaje"),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              "ITEMS VERIFICADOS OK: $totalOK",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "FALTANTES DETECTADOS:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red),
            ),
            pw.SizedBox(height: 6),
            if (faltantes.isEmpty)
              pw.Text("Ningún faltante detectado.")
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: faltantes
                    .map(
                      (item) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text(item),
                      ),
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 50),
            pw.Text(
              "Firma del responsable:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 80,
              width: 200,
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              alignment: pw.Alignment.center,
              child: pw.Text(
                tieneFirma ? "Firma digital registrada" : "Firma digital no disponible",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: 'reporte_${nombreViaje.replaceAll(' ', '_')}.pdf');
}