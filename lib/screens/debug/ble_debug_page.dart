import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/ble_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class BleDebugPage extends ConsumerStatefulWidget {
  const BleDebugPage({super.key});

  @override
  ConsumerState<BleDebugPage> createState() => _BleDebugPageState();
}

class _BleDebugPageState extends ConsumerState<BleDebugPage> {
  final _sendController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _sendController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(BleController ctl, BleState state) {
    if (!state.canSend) return;
    final text = _sendController.text.trim();
    if (text.isEmpty) return;
    ctl.send(text);
    _sendController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bleControllerProvider);
    final ctl = ref.read(bleControllerProvider.notifier);

    // Auto-scroll log to bottom on each build (new entries)
    _scrollToBottom();

    return Scaffold(
      backgroundColor: KColors.cardBg,
      appBar: AppBar(
        backgroundColor: KColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'BLE Debug',
          style: montserrat(size: context.r(18), color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status row ────────────────────────────────────────────────────
          _StatusRow(state: state, r: context.r),

          // ── Error banner ──────────────────────────────────────────────────
          if (state.lastError != null) _ErrorBanner(message: state.lastError!, r: context.r),

          // ── Scan button ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(12),
              context.r(10),
              context.r(12),
              0,
            ),
            child: _ScanButton(state: state, ctl: ctl, r: context.r),
          ),

          // ── Device list / connected card ──────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.r(12),
              vertical: context.r(8),
            ),
            child: state.status == BleStatus.connected
                ? _ConnectedCard(state: state, ctl: ctl, r: context.r)
                : _ScanResultsList(state: state, ctl: ctl, r: context.r),
          ),

          // ── Log console (takes remaining space) ───────────────────────────
          Expanded(
            child: _LogConsole(
              state: state,
              scrollController: _scrollController,
              onClear: ctl.clearLog,
              r: context.r,
            ),
          ),

          // ── Send row (pinned bottom) ───────────────────────────────────────
          _SendRow(
            state: state,
            controller: _sendController,
            onSend: () => _send(ctl, state),
            r: context.r,
            bottomInset: MediaQuery.paddingOf(context).bottom,
          ),
        ],
      ),
    );
  }
}

// ─── Status Row ──────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final BleState state;
  final double Function(double) r;

  const _StatusRow({required this.state, required this.r});

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    final String chipLabel;
    switch (state.status) {
      case BleStatus.idle:
        chipColor = Colors.grey;
        chipLabel = 'idle';
      case BleStatus.scanning:
        chipColor = KColors.orange;
        chipLabel = 'scanning';
      case BleStatus.connecting:
        chipColor = KColors.blue;
        chipLabel = 'connecting';
      case BleStatus.connected:
        chipColor = KColors.teal;
        chipLabel = 'connected';
    }

    return Container(
      color: KColors.navyText.withAlpha(13), // ~5% opacity
      padding: EdgeInsets.symmetric(
        horizontal: r(16),
        vertical: r(8),
      ),
      child: Row(
        children: [
          Chip(
            label: Text(
              chipLabel,
              style: montserrat(size: r(11), color: Colors.white),
            ),
            backgroundColor: chipColor,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: r(6)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          if (state.status == BleStatus.connected &&
              state.connectedName != null) ...[
            SizedBox(width: r(10)),
            Expanded(
              child: Text(
                state.connectedName!,
                style: thaiSans(size: r(13), color: KColors.navyText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final double Function(double) r;

  const _ErrorBanner({required this.message, required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFEBEE), // red.shade100
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(6)),
      child: Text(
        message,
        style: thaiSans(size: r(12), color: const Color(0xFFC62828)), // red.shade800
      ),
    );
  }
}

// ─── Scan Button ──────────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final BleState state;
  final BleController ctl;
  final double Function(double) r;

  const _ScanButton({required this.state, required this.ctl, required this.r});

  @override
  Widget build(BuildContext context) {
    final isScanning = state.status == BleStatus.scanning;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey.shade600 : KColors.teal,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: r(12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r(10)),
        ),
        elevation: 1,
      ),
      icon: isScanning
          ? SizedBox(
              width: r(18),
              height: r(18),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(Icons.bluetooth_searching, size: r(20)),
      label: Text(
        isScanning ? 'หยุดสแกน' : 'สแกน',
        style: thaiSans(size: r(15), color: Colors.white),
      ),
      onPressed: isScanning ? ctl.stopScan : ctl.startScan,
    );
  }
}

// ─── Scan Results List ────────────────────────────────────────────────────────

class _ScanResultsList extends StatelessWidget {
  final BleState state;
  final BleController ctl;
  final double Function(double) r;

  const _ScanResultsList({
    required this.state,
    required this.ctl,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final results = state.scanResults;
    final isConnecting = state.status == BleStatus.connecting;

    if (results.isEmpty && state.status == BleStatus.idle) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: r(12)),
        child: Center(
          child: Text(
            'ไม่พบอุปกรณ์',
            style: thaiSans(size: r(14), color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r(10)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 12, endIndent: 12),
        itemBuilder: (context, i) {
          final d = results[i];
          final displayName = d.name == '(unknown)' ? d.id : d.name;
          return ListTile(
            dense: true,
            enabled: !isConnecting,
            title: Text(
              displayName,
              style: thaiSans(size: r(14), color: KColors.navyText),
            ),
            subtitle: Text(
              d.id,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: r(10),
                color: Colors.grey,
              ),
            ),
            trailing: Text(
              '${d.rssi} dBm',
              style: montserrat(
                size: r(12),
                color: KColors.navyText,
                weight: FontWeight.w500,
              ),
            ),
            onTap: isConnecting ? null : () => ctl.connect(d.id),
          );
        },
      ),
    );
  }
}

// ─── Connected Card ───────────────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  final BleState state;
  final BleController ctl;
  final double Function(double) r;

  const _ConnectedCard({
    required this.state,
    required this.ctl,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final name = state.connectedName ?? state.connectedId ?? 'ESP32';

    return Container(
      decoration: BoxDecoration(
        color: KColors.teal.withAlpha(26), // ~10% opacity
        borderRadius: BorderRadius.circular(r(10)),
        border: Border.all(color: KColors.teal, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: r(12), vertical: r(10)),
      child: Row(
        children: [
          Icon(Icons.bluetooth_connected, color: KColors.teal, size: r(20)),
          SizedBox(width: r(8)),
          Expanded(
            child: Text(
              name,
              style: thaiSans(size: r(14), color: KColors.navyText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: r(8)),
            ),
            onPressed: ctl.disconnect,
            child: Text(
              'ตัดการเชื่อมต่อ',
              style: thaiSans(size: r(13), color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Console ─────────────────────────────────────────────────────────────

class _LogConsole extends StatelessWidget {
  final BleState state;
  final ScrollController scrollController;
  final VoidCallback onClear;
  final double Function(double) r;

  const _LogConsole({
    required this.state,
    required this.scrollController,
    required this.onClear,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          color: KColors.navyText,
          padding: EdgeInsets.symmetric(horizontal: r(12), vertical: r(6)),
          child: Row(
            children: [
              Text(
                'LOG',
                style: montserrat(size: r(12), color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'ล้าง',
                  style: thaiSans(size: r(12), color: KColors.teal),
                ),
              ),
            ],
          ),
        ),
        // Console body
        Expanded(
          child: Container(
            color: const Color(0xFF1A1A2E),
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(r(8)),
              itemCount: state.log.length,
              itemBuilder: (context, i) => _LogLine(entry: state.log[i], r: r),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogLine extends StatelessWidget {
  final BleLogEntry entry;
  final double Function(double) r;

  const _LogLine({required this.entry, required this.r});

  @override
  Widget build(BuildContext context) {
    final Color prefixColor;
    final String prefix;
    switch (entry.kind) {
      case BleLogKind.rx:
        prefix = 'RX';
        prefixColor = KColors.greenDark;
      case BleLogKind.tx:
        prefix = 'TX';
        prefixColor = KColors.blue;
      case BleLogKind.sys:
        prefix = 'SYS';
        prefixColor = Colors.grey;
    }

    final t = entry.time;
    final ts = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontFamily: 'monospace', fontSize: r(11)),
          children: [
            TextSpan(
              text: '$ts ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: '[$prefix] ',
              style: TextStyle(
                color: prefixColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: entry.text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Send Row ─────────────────────────────────────────────────────────────────

class _SendRow extends StatelessWidget {
  final BleState state;
  final TextEditingController controller;
  final VoidCallback onSend;
  final double Function(double) r;
  final double bottomInset;

  const _SendRow({
    required this.state,
    required this.controller,
    required this.onSend,
    required this.r,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KColors.cardBg,
      padding: EdgeInsets.fromLTRB(r(12), r(8), r(12), r(12) + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: state.canSend,
              textInputAction: TextInputAction.send,
              onSubmitted: state.canSend ? (_) => onSend() : null,
              style: TextStyle(fontFamily: 'monospace', fontSize: r(14)),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: r(12),
                  vertical: r(10),
                ),
                hintText: 'Type command…',
                hintStyle: TextStyle(color: Colors.grey, fontSize: r(13)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r(8)),
                  borderSide: const BorderSide(color: KColors.teal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r(8)),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r(8)),
                  borderSide: const BorderSide(color: KColors.teal, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(r(8)),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          SizedBox(width: r(8)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.teal,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: r(16),
                vertical: r(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r(8)),
              ),
              elevation: 1,
            ),
            onPressed: state.canSend ? onSend : null,
            child: Text(
              'ส่ง',
              style: thaiSans(size: r(15), color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
