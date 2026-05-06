import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recognition_history.dart';

class PdfExportService {
  
  Future<File> generateRecognitionPdf(RecognitionHistory history) async {
    final pdf = pw.Document();
    
    // Charger l'image si elle existe
    pw.MemoryImage? image;
    final imageFile = File(history.imagePath);
    if (await imageFile.exists()) {
      final imageBytes = await imageFile.readAsBytes();
      image = pw.MemoryImage(imageBytes);
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Rapport de Reconnaissance d\'Écriture',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Généré le ${_formatDate(history.timestamp)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 20),
            
            // Informations
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📊 Informations',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildInfoRow('📝 Caractères', '${history.charactersCount}'),
                  _buildInfoRow('📖 Mots', '${history.wordsCount}'),
                  _buildInfoRow('📄 Lignes', '${history.linesCount}'),
                  _buildInfoRow('🔤 Script', history.scriptUsed),
                  _buildInfoRow('🕐 Heure', _formatTime(history.timestamp)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Image originale
            if (image != null) ...[
              pw.Text(
                '🖼️ Image originale',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                height: 200,
                child: pw.Image(image),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Texte reconnu
            pw.Text(
              '📝 Texte reconnu',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                history.recognizedText,
                style: pw.TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Pied de page
            pw.Center(
              child: pw.Text(
                'Document généré par Smart Vision AI',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/recognition_${history.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  Future<File> generateMultipleRecognitionPdf(List<RecognitionHistory> histories) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final List<pw.Widget> children = [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Rapport Complet - Reconnaissances',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${histories.length} reconnaissances',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Généré le ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Divider(),
          ];
          
          for (var i = 0; i < histories.length; i++) {
            final history = histories[i];
            children.addAll([
              pw.SizedBox(height: 20),
              pw.Text(
                'Reconnaissance #${i + 1}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${_formatDateTime(history.timestamp)}'),
              pw.SizedBox(height: 10),
              pw.Text(
                'Texte: ${history.recognizedText.length > 200 ? history.recognizedText.substring(0, 200) + '...' : history.recognizedText}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Statistiques: ${history.charactersCount} caractères, ${history.wordsCount} mots'),
              if (i < histories.length - 1) pw.Divider(),
            ]);
          }
          
          return children;
        },
      ),
    );
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/recognition_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(': $value'),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }
}