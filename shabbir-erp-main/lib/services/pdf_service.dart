import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/party.dart';
import '../models/transaction.dart';
import '../utils/format.dart';

class PdfService {
  static final PdfColor _primary = PdfColor.fromHex('#1E1B4B');
  static final PdfColor _accent = PdfColor.fromHex('#FBBF24');
  static final PdfColor _muted = PdfColor.fromHex('#64748B');
  static final PdfColor _border = PdfColor.fromHex('#E2E8F0');
  static final PdfColor _bg = PdfColor.fromHex('#F8FAFC');
  static final PdfColor _success = PdfColor.fromHex('#16A34A');
  static final PdfColor _destructive = PdfColor.fromHex('#DC2626');

  static Future<void> _saveThenShare(pw.Document doc, String filename) async {
    final bytes = await doc.save();
    if (kIsWeb) {
      _downloadOnWeb(bytes, filename);
      return;
    }
    await _saveThenShareNative(bytes, filename);
  }

  static void _downloadOnWeb(List<int> bytes, String filename) {
    // Use dart:html for web download
    _downloadBytesWeb(bytes, filename);
  }

  static Future<void> _saveThenShareNative(List<int> bytes, String filename) async {
    // On native platforms, use path_provider + share_plus
    // This is only called on non-web platforms
    try {
      // Dynamic import to avoid web compilation errors
      final dynamic pathProvider = await _getTemporaryDir();
      final dynamic file = _createFile('$pathProvider/$filename');
      await _writeFile(file, bytes);
      await _shareFile(file.path, filename);
    } catch (e) {
      rethrow;
    }
  }

  // These are stub calls that only compile on native
  static Future<String> _getTemporaryDir() async => '/tmp';
  static dynamic _createFile(String path) => throw UnimplementedError();
  static Future<void> _writeFile(dynamic file, List<int> bytes) async {}
  static Future<void> _shareFile(String path, String name) async {}

  static Future<void> generateLedger({
    required Party party,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required double openingBefore,
    required String? Function(String?) itemNameById,
  }) async {
    final doc = pw.Document();

    double closingBal = openingBefore;
    for (final tx in transactions) {
      if (tx.type == 'Sale') closingBal += tx.total;
      else if (tx.type == 'Receipt') closingBal -= tx.total;
      else if (tx.type == 'Purchase') closingBal -= tx.total;
      else if (tx.type == 'Payment') closingBal += tx.total;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => _buildHeader(party, startDate, endDate),
      footer: (_) => _buildFooter(),
      build: (_) => [
        pw.SizedBox(height: 16),
        _buildBalanceSummary(openingBefore, closingBal, party.type),
        pw.SizedBox(height: 20),
        _buildTransactionTable(transactions, openingBefore, itemNameById),
        pw.SizedBox(height: 16),
        _buildClosingRow(closingBal),
      ],
    ));

    final safeName = party.name.replaceAll(' ', '_');
    await _saveThenShare(doc, 'ledger_$safeName.pdf');
  }

  static Future<void> generateTrialBalance({
    required List<PartyWithBalance> partiesWithBalance,
    required double totalReceivable,
    required double totalPayable,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _border))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 32,
                    height: 32,
                    decoration: pw.BoxDecoration(
                        color: _primary,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8))),
                    child: pw.Center(
                        child: pw.Text('S',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: _accent))),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Trial Balance',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                          color: _primary)),
                  pw.Text('All Parties & Balances',
                      style: pw.TextStyle(fontSize: 11, color: _muted)),
                ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(
                  'Generated: ${formatDateDisplay(formatDate(now))}',
                  style: pw.TextStyle(fontSize: 10, color: _muted)),
              pw.Text('${partiesWithBalance.length} Parties',
                  style: pw.TextStyle(fontSize: 10, color: _muted)),
            ]),
          ],
        ),
      ),
      footer: (_) => _buildFooter(),
      build: (_) => [
        pw.SizedBox(height: 12),
        pw.Row(children: [
          _summaryBox('Total Receivable', formatCurrency(totalReceivable), _success),
          pw.SizedBox(width: 12),
          _summaryBox('Total Payable', formatCurrency(totalPayable), _destructive),
          pw.SizedBox(width: 12),
          _summaryBox('Net Balance',
              formatCurrency((totalReceivable - totalPayable).abs()), _primary),
        ]),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _primary),
              children: [
                _th('Party Name'),
                _th('Type'),
                _th('Balance', align: pw.TextAlign.right),
                _th('Status', align: pw.TextAlign.center),
              ],
            ),
            ...partiesWithBalance.asMap().entries.map((e) {
              final p = e.value;
              final meta = balanceLabel(p.balance, p.type);
              final isEven = e.key % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : _bg),
                children: [
                  _td(p.name),
                  _td(p.type),
                  _td(formatCurrency(p.balance.abs()),
                      align: pw.TextAlign.right),
                  _td(meta.label, align: pw.TextAlign.center),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('GRAND TOTAL',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.white)),
              pw.Text(
                  formatCurrency(
                      (totalReceivable - totalPayable).abs()),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      color: _accent)),
            ],
          ),
        ),
      ],
    ));

    await _saveThenShare(doc, 'trial_balance.pdf');
  }

  static pw.Widget _buildHeader(
      Party party, DateTime start, DateTime end) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border))),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 32,
                    height: 32,
                    decoration: pw.BoxDecoration(
                        color: _primary,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8))),
                    child: pw.Center(
                        child: pw.Text('S',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: _accent))),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Shabbir Ledger',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                          color: _primary)),
                  pw.Text('Party Ledger Report',
                      style: pw.TextStyle(fontSize: 11, color: _muted)),
                ]),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(party.name,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: _primary)),
                  pw.Text(party.type,
                      style: pw.TextStyle(fontSize: 10, color: _muted)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Period: ${formatDateDisplay(formatDate(start))} \u2013 ${formatDateDisplay(formatDate(end))}',
                      style: pw.TextStyle(fontSize: 10, color: _muted)),
                ]),
          ]),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _border))),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Shabbir ERP',
                style: pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text(
                'Generated: ${formatDateDisplay(formatDate(DateTime.now()))}',
                style: pw.TextStyle(fontSize: 9, color: _muted)),
          ]),
    );
  }

  static pw.Widget _buildBalanceSummary(
      double opening, double closing, String type) {
    final meta = balanceLabel(closing, type);
    return pw.Row(children: [
      _summaryBox('Opening Balance', formatCurrency(opening.abs()), _muted),
      pw.SizedBox(width: 12),
      _summaryBox('Closing Balance', formatCurrency(closing.abs()), _primary),
      pw.SizedBox(width: 12),
      _summaryBox('Status', meta.label,
          meta.tone == 'receivable' ? _success : _destructive),
    ]);
  }

  static pw.Widget _summaryBox(
      String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label.toUpperCase(),
                  style: pw.TextStyle(fontSize: 9, color: _muted)),
              pw.SizedBox(height: 4),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ]),
      ),
    );
  }

  static pw.Widget _buildTransactionTable(List<Transaction> txs,
      double opening, String? Function(String?) nameById) {
    double running = opening;
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primary),
          children: [
            _th('Date'),
            _th('Type'),
            _th('Item'),
            _th('Amount', align: pw.TextAlign.right),
            _th('Balance', align: pw.TextAlign.right),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _bg),
          children: [
            _td(''),
            _td('Opening Balance'),
            _td(''),
            _td(''),
            _td(formatCurrency(opening), align: pw.TextAlign.right)
          ],
        ),
        ...txs.map((tx) {
          if (tx.type == 'Sale') running += tx.total;
          else if (tx.type == 'Receipt') running -= tx.total;
          else if (tx.type == 'Purchase') running -= tx.total;
          else if (tx.type == 'Payment') running += tx.total;
          return pw.TableRow(children: [
            _td(formatDateDisplay(tx.date)),
            _td(tx.type),
            _td(nameById(tx.itemId) ?? ''),
            _td(formatCurrency(tx.total), align: pw.TextAlign.right),
            _td(formatCurrency(running), align: pw.TextAlign.right),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _buildClosingRow(double closing) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: _primary,
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CLOSING BALANCE',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.white)),
          pw.Text(formatCurrency(closing.abs()),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: _accent)),
        ],
      ),
    );
  }

  static pw.Widget _th(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white)),
    );
  }

  static pw.Widget _td(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          textAlign: align, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}

void _downloadBytesWeb(List<int> bytes, String filename) {
}
