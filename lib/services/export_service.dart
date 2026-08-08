import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class ExportService {
  static Future<void> exportTransactionsToCSV({
    required List<TransactionModel> transactions,
    required Map<String, Category> categories,
  }) async {
    List<List<dynamic>> rows = [];
    
    // CSV Header
    rows.add([
      'Date',
      'Title',
      'Type',
      'Category',
      'Amount',
      'Notes',
    ]);

    // Data Rows
    for (var t in transactions) {
      final categoryName = categories[t.categoryId]?.name ?? 'Unknown';
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        t.title,
        t.type.toUpperCase(),
        categoryName,
        t.amount,
        t.notes ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'Cash Management Transactions Export (CSV)');
  }

  static Future<void> exportTransactionsToPDF({
    required List<TransactionModel> transactions,
    required Map<String, Category> categories,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cash Management Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Date', 'Title', 'Type', 'Category', 'Amount'],
              data: transactions.map((t) {
                final categoryName = categories[t.categoryId]?.name ?? 'Unknown';
                final isExpense = t.type == 'expense';
                final amountStr = '${isExpense ? '-' : '+'}$currencySymbol${t.amount.toStringAsFixed(2)}';
                return [
                  DateFormat('yyyy-MM-dd').format(t.date),
                  t.title,
                  t.type.toUpperCase(),
                  categoryName,
                  amountStr,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(path)], text: 'Cash Management Transactions Report (PDF)');
  }
}
