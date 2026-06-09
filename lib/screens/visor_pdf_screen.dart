import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class VisorPdfScreen extends StatelessWidget {
  final String titulo;
  final String urlPdf;

  const VisorPdfScreen({super.key, required this.titulo, required this.urlPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
      ),
      // Syncfusion maneja el zoom y desplazamiento automáticamente
      body: SfPdfViewer.network(
        urlPdf,
        enableDoubleTapZooming: true,
      ),
    );
  }
}