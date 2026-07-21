import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/assessment_record.dart';

/// Builds a formal one-page "แบบบันทึกการประเมินสมรรถภาพทางกาย" PDF from a saved
/// [AssessmentRecord] and opens the system print/save sheet. Mirrors the layout
/// of the paper record sheet from the elderly-fitness manual, but filled with
/// THIS app's tests (SPPB: การทรงตัว / การเดิน / ลุก-นั่งเก้าอี้ + BMI) and the
/// user's real measured data — so a physio can file it like the official form.
class AssessmentPdf {
  // Form palette — medium clinical blue header, pale blue zebra rows.
  static const _blue = PdfColor.fromInt(0xFF2A86BE);
  static const _blueDark = PdfColor.fromInt(0xFF1F6E9E);
  static const _rowAlt = PdfColor.fromInt(0xFFEAF4FA);
  static const _ink = PdfColor.fromInt(0xFF1F2F4A);
  static const _line = PdfColor.fromInt(0xFFBFD6E4);

  /// Generate + open the native print/share dialog for [record].
  static Future<void> generateAndShare(AssessmentRecord record) async {
    final base = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Kanit-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Kanit-Bold.ttf'));

    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: base, bold: bold)
        .copyWith(defaultTextStyle: pw.TextStyle(font: base, color: _ink));

    doc.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(record, bold),
            pw.SizedBox(height: 12),
            _personBlock(record, base, bold),
            pw.SizedBox(height: 14),
            _sectionLabel('การทดสอบสมรรถภาพ', bold),
            pw.SizedBox(height: 6),
            _resultsTable(record, base, bold),
            pw.SizedBox(height: 14),
            _summaryBox(record, base, bold),
            pw.Spacer(),
            _footer(base),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: 'kinex-assessment-${record.id}.pdf',
      onLayout: (format) => doc.save(),
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────────
  static pw.Widget _header(AssessmentRecord r, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text('แบบบันทึกการประเมินสมรรถภาพทางกาย',
              style: pw.TextStyle(font: bold, fontSize: 20, color: _blueDark)),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text('KINEX — รายงานการประเมินสมรรถภาพผู้สูงอายุ',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('วันที่ ${_thaiDate(r.dateTime)}',
              style: const pw.TextStyle(fontSize: 11)),
        ),
        pw.Divider(color: _blue, thickness: 1.4, height: 6),
      ],
    );
  }

  // ── Person / vitals line ────────────────────────────────────────────────────
  static pw.Widget _personBlock(AssessmentRecord r, pw.Font base, pw.Font bold) {
    final p = r.person;
    final name = (p.name != null && p.name!.isNotEmpty) ? p.name! : '-';
    final bp = (p.systolic != null && p.diastolic != null)
        ? '${p.systolic}/${p.diastolic}'
        : '-';
    final pulse = p.pulse?.toString() ?? '-';
    pw.Widget field(String label, String value, {double flex = 1}) => pw.Expanded(
          flex: (flex * 10).round(),
          child: pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(font: base, fontSize: 11.5, color: _ink),
              children: [
                pw.TextSpan(text: '$label  '),
                pw.TextSpan(
                    text: value,
                    style: pw.TextStyle(font: bold, color: _blueDark)),
              ],
            ),
          ),
        );
    return pw.Column(
      children: [
        pw.Row(children: [
          field('ชื่อ-นามสกุล', name, flex: 2.4),
          field('อายุ', '${p.age} ปี'),
          field('เพศ', p.gender.thaiLabel),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          field('ความดันโลหิต', '$bp มม.ปรอท', flex: 1.6),
          field('ชีพจร', '$pulse ครั้ง/นาที', flex: 1.6),
        ]),
      ],
    );
  }

  static pw.Widget _sectionLabel(String text, pw.Font bold) => pw.Text(text,
      style: pw.TextStyle(font: bold, fontSize: 13, color: _blueDark));

  // ── Results table ──────────────────────────────────────────────────────────
  static pw.Widget _resultsTable(
      AssessmentRecord r, pw.Font base, pw.Font bold) {
    final rows = <_Row>[
      _Row('1', 'น้ำหนัก\n(Weight)', '${_num(r.weight.value)} กิโลกรัม', '-'),
      _Row('2', 'ส่วนสูง\n(Height)', '${_num(r.height.value)} เซนติเมตร', '-'),
      _Row('3', 'ดัชนีมวลกาย\n(Body Mass Index : BMI)',
          '${_num(r.bmi.value)} กก./ม.²', r.bmi.band.thaiLabel),
      _Row(
          '4',
          'การทรงตัว\n(Balance Test)',
          'ยืนต่อเท้า ${_num(r.balance.tandemSec)} วินาที\n'
              '(ชิด ${_num(r.balance.sideBySideSec)}s · กึ่ง ${_num(r.balance.semiTandemSec)}s)',
          _interpret(r.balance.points)),
      _Row(
          '5',
          'ความเร็วในการเดิน 4 เมตร\n(Gait Speed Test)',
          r.gait.unable ? 'เดินไม่ได้' : '${_num(r.gait.seconds)} วินาที',
          _interpret(r.gait.points)),
      _Row(
          '6',
          'ลุกยืน-นั่งบนเก้าอี้ 5 ครั้ง\n(Five-Times Sit-to-Stand)',
          r.chairStand.preTestPassed
              ? '${_num(r.chairStand.seconds)} วินาที'
              : 'ลุกยืนไม่ได้',
          _interpret(r.chairStand.points)),
    ];

    const w = {
      0: pw.FixedColumnWidth(38),
      1: pw.FlexColumnWidth(3.1),
      2: pw.FlexColumnWidth(2.7),
      3: pw.FlexColumnWidth(1.7),
    };

    pw.Widget cell(String t, pw.Font f,
            {PdfColor color = _ink,
            pw.TextAlign align = pw.TextAlign.left,
            double size = 10.5,
            bool header = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(t,
              textAlign: align,
              style: pw.TextStyle(
                  font: f,
                  fontSize: header ? 11 : size,
                  color: header ? PdfColors.white : color)),
        );

    final table = pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.8),
      columnWidths: w,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: [
            cell('ลำดับ', bold, align: pw.TextAlign.center, header: true),
            cell('การทดสอบสมรรถภาพ', bold, header: true),
            cell('ผลการทดสอบ', bold, header: true),
            cell('การแปลผล', bold, align: pw.TextAlign.center, header: true),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              cell(rows[i].no, base, align: pw.TextAlign.center),
              cell(rows[i].test, bold, color: _ink, size: 10.5),
              cell(rows[i].result, base),
              cell(rows[i].interp, bold,
                  align: pw.TextAlign.center, color: _blueDark),
            ],
          ),
      ],
    );
    return table;
  }

  // ── Overall SPPB summary ────────────────────────────────────────────────────
  static pw.Widget _summaryBox(AssessmentRecord r, pw.Font base, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _rowAlt,
        border: pw.Border.all(color: _blue, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: base, fontSize: 12, color: _ink),
                children: [
                  const pw.TextSpan(text: 'คะแนนรวม SPPB  '),
                  pw.TextSpan(
                      text: '${r.totalScore} / 12',
                      style: pw.TextStyle(
                          font: bold, fontSize: 15, color: _blueDark)),
                  pw.TextSpan(text: '   (ช่วงคะแนน ${r.risk.scoreRange})'),
                ],
              ),
            ),
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
                color: _blueDark, borderRadius: pw.BorderRadius.circular(20)),
            child: pw.Text('${r.risk.thaiLabel}  (${r.risk.englishLabel})',
                style: pw.TextStyle(
                    font: bold, fontSize: 11.5, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Font base) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Divider(color: _line, thickness: 0.8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ลงชื่อผู้ประเมิน ..............................................',
                  style: pw.TextStyle(font: base, fontSize: 10.5)),
              pw.Text('ออกโดยแอปพลิเคชัน KINEX',
                  style: pw.TextStyle(
                      font: base, fontSize: 9, color: PdfColors.grey500)),
            ],
          ),
        ],
      );

  // ── helpers ─────────────────────────────────────────────────────────────────
  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  // SPPB domain points (0–4) → Thai interpretation word, matching the manual's
  // ดีมาก / ดี / พอใช้ / น้อย / เสี่ยง bands on the paper form's การแปลผล column.
  static String _interpret(int points) => switch (points) {
        4 => 'ดีมาก',
        3 => 'ดี',
        2 => 'พอใช้',
        1 => 'น้อย',
        _ => 'เสี่ยง',
      };

  static String _thaiDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year + 543}'; // Buddhist era, as on the form
}

class _Row {
  final String no, test, result, interp;
  const _Row(this.no, this.test, this.result, this.interp);
}
