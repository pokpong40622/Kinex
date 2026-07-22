import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Public enums ────────────────────────────────────────────────────────────

enum BleStatus { idle, scanning, connecting, connected }

enum BleLogKind { rx, tx, sys }

// ─── Public data classes ─────────────────────────────────────────────────────

class BleDeviceInfo {
  final String id;
  final String name;
  final int rssi;
  const BleDeviceInfo({required this.id, required this.name, required this.rssi});
}

class BleLogEntry {
  final BleLogKind kind;
  final String text;
  final DateTime time;
  const BleLogEntry(this.kind, this.text, this.time);
}

class BleState {
  final BleStatus status;
  final List<BleDeviceInfo> scanResults; // sorted by rssi desc, deduped by id
  final String? connectedId;
  final String? connectedName;
  final List<BleLogEntry> log; // chronological, newest LAST; capped at ~200
  final bool canSend; // true when a writable characteristic is ready
  final String? lastError;
  final bool needsSettings; // BT permission permanently denied → open settings

  const BleState({
    required this.status,
    required this.scanResults,
    this.connectedId,
    this.connectedName,
    required this.log,
    required this.canSend,
    this.lastError,
    this.needsSettings = false,
  });

  BleState copyWith({
    BleStatus? status,
    List<BleDeviceInfo>? scanResults,
    String? connectedId,
    String? connectedName,
    List<BleLogEntry>? log,
    bool? canSend,
    String? lastError,
    bool? needsSettings,
    bool clearConnected = false,
    bool clearError = false,
  }) {
    return BleState(
      status: status ?? this.status,
      scanResults: scanResults ?? this.scanResults,
      connectedId: clearConnected ? null : (connectedId ?? this.connectedId),
      connectedName: clearConnected ? null : (connectedName ?? this.connectedName),
      log: log ?? this.log,
      canSend: canSend ?? this.canSend,
      lastError: clearError ? null : (lastError ?? this.lastError),
      needsSettings: needsSettings ?? this.needsSettings,
    );
  }

  static const BleState initial = BleState(
    status: BleStatus.idle,
    scanResults: [],
    log: [],
    canSend: false,
  );
}

// ─── Controller ──────────────────────────────────────────────────────────────

class BleController extends Notifier<BleState> {
  // Nordic UART Service UUIDs
  static const _nusService = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const _nusWrite   = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const _nusNotify  = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  static const _maxLog = 200;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _scanDoneSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final List<StreamSubscription<List<int>>> _notifySubs = [];

  // Broadcast of every decoded line received from the device (one per notify).
  // Feature screens (e.g. the EMG capture step) listen here to parse data
  // samples, while the debug console just logs them.
  final StreamController<String> _incoming = StreamController<String>.broadcast();
  Stream<String> get incoming => _incoming.stream;

  // ─── Riverpod ─────────────────────────────────────────────────────────────

  @override
  BleState build() => BleState.initial;

  // ─── Log helpers ──────────────────────────────────────────────────────────

  void _log(BleLogKind kind, String text) {
    var log = [...state.log, BleLogEntry(kind, text, DateTime.now())];
    if (log.length > _maxLog) log = log.sublist(log.length - _maxLog);
    state = state.copyWith(log: log);
  }

  void _setError(String msg) {
    _log(BleLogKind.sys, 'error: $msg');
    state = state.copyWith(lastError: msg);
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    // Request all three. On Android 12+ the manifest marks BLUETOOTH_SCAN
    // neverForLocation, so only scan + connect actually gate BLE — location is
    // best-effort (needed only on older Android) and must NOT hard-fail here.
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scan = statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
    final connect =
        statuses[Permission.bluetoothConnect] ?? PermissionStatus.denied;

    if (scan.isGranted && connect.isGranted) {
      state = state.copyWith(needsSettings: false);
      return true;
    }

    // The OS won't show the dialog again once "don't ask again" was chosen —
    // flag it so the UI can offer to open the app's settings page instead.
    final permanent = scan.isPermanentlyDenied || connect.isPermanentlyDenied;
    state = state.copyWith(needsSettings: permanent);
    _setError(permanent
        ? 'ต้องเปิดสิทธิ์ Bluetooth ในการตั้งค่าแอป'
        : 'ต้องอนุญาตการเข้าถึง Bluetooth');
    return false;
  }

  // ─── Adapter helper ───────────────────────────────────────────────────────

  /// On a cold launch [FlutterBluePlus.adapterStateNow] returns
  /// [BluetoothAdapterState.unknown] until the first adapterState event fires.
  /// Waiting for the first non-unknown value (with a 2 s safety timeout)
  /// avoids the false "BT is off" bail that required toggling Bluetooth.
  Future<BluetoothAdapterState> _ensureAdapterReady() async {
    var s = FlutterBluePlus.adapterStateNow;
    if (s == BluetoothAdapterState.unknown) {
      s = await FlutterBluePlus.adapterState
          .firstWhere((v) => v != BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 2),
              onTimeout: () => FlutterBluePlus.adapterStateNow);
    }
    return s;
  }

  // ─── Scan ─────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    try {
      if (!await _requestPermissions()) return;

      final adapter = await _ensureAdapterReady();
      if (adapter != BluetoothAdapterState.on) {
        _log(BleLogKind.sys, 'Bluetooth is off — please turn it on');
        try {
          await FlutterBluePlus.turnOn(); // Android only; no-op / throws on others
        } catch (_) {
          // User must enable Bluetooth manually on this platform
        }
        return;
      }

      // Reset for fresh scan
      _scanSub?.cancel();
      _scanDoneSub?.cancel();

      state = state.copyWith(
        status: BleStatus.scanning,
        scanResults: [],
        clearError: true,
      );

      // Subscribe to scan results BEFORE startScan (required by onScanResults contract)
      _scanSub = FlutterBluePlus.onScanResults.listen(
        (results) {
          // Dedupe by id, keep highest rssi per device
          final deduped = <String, BleDeviceInfo>{};
          for (final r in results) {
            final id = r.device.remoteId.str;
            final pName = r.device.platformName;
            final aName = r.advertisementData.advName;
            final name = pName.isNotEmpty
                ? pName
                : aName.isNotEmpty
                    ? aName
                    : '(unknown)';
            if (!deduped.containsKey(id) || r.rssi > deduped[id]!.rssi) {
              deduped[id] = BleDeviceInfo(id: id, name: name, rssi: r.rssi);
            }
          }
          final sorted = deduped.values.toList()
            ..sort((a, b) => b.rssi.compareTo(a.rssi));
          state = state.copyWith(scanResults: sorted);
        },
        onError: (Object e) => _setError('Scan stream error: $e'),
      );

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      _log(BleLogKind.sys, 'Scan started (8 s)');

      // Subscribe to isScanning AFTER startScan so initial re-emit is `true`.
      // When it flips to `false` the scan has ended (timeout or stopScan).
      _scanDoneSub = FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && state.status == BleStatus.scanning) {
          state = state.copyWith(status: BleStatus.idle);
          _log(BleLogKind.sys,
              'Scan finished — ${state.scanResults.length} device(s) found');
        }
      });
    } catch (e) {
      _setError('startScan: $e');
      _scanSub?.cancel();
      state = state.copyWith(status: BleStatus.idle);
    }
  }

  Future<void> stopScan() async {
    try {
      // Cancel listeners before calling stopScan to avoid double state-update
      _scanSub?.cancel();
      _scanDoneSub?.cancel();
      _scanSub = null;
      _scanDoneSub = null;

      await FlutterBluePlus.stopScan();

      if (state.status == BleStatus.scanning) {
        state = state.copyWith(status: BleStatus.idle);
        _log(BleLogKind.sys, 'Scan stopped');
      }
    } catch (e) {
      _setError('stopScan: $e');
    }
  }

  // ─── Quick connect (top-bar button) ───────────────────────────────────────

  /// One-tap connect: scans briefly and connects to the first matching device.
  /// Default matching is "name contains [namePrefix]" (case-insensitive) — kept
  /// for backward compatibility. Pass [matches] to use a custom predicate
  /// instead (the suffix-based Hand/Leg-L/Leg-R matching below); when given,
  /// [namePrefix] is ignored. The full device picker still lives in the BLE
  /// Debug window.
  Future<void> quickConnect({
    String namePrefix = 'Kinex-EMG',
    bool Function(String lowerName)? matches,
  }) async {
    try {
      if (state.status == BleStatus.connected ||
          state.status == BleStatus.connecting) {
        return;
      }
      if (!await _requestPermissions()) return;

      final adapter = await _ensureAdapterReady();
      if (adapter != BluetoothAdapterState.on) {
        _log(BleLogKind.sys, 'Bluetooth is off — please turn it on');
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
        return;
      }

      _scanSub?.cancel();
      _scanDoneSub?.cancel();

      state = state.copyWith(
        status: BleStatus.scanning,
        scanResults: [],
        clearError: true,
      );
      _log(BleLogKind.sys, 'Quick-connect: scanning…');

      final lower = namePrefix.toLowerCase();
      final match = matches ?? (String n) => n.contains(lower);
      var connecting = false;

      _scanSub = FlutterBluePlus.onScanResults.listen(
        (results) async {
          if (connecting) return;
          for (final r in results) {
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : r.advertisementData.advName;
            if (match(name.trim().toLowerCase())) {
              connecting = true;
              final id = r.device.remoteId.str;
              await stopScan();
              await connect(id);
              return;
            }
          }
        },
        onError: (Object e) => _setError('Scan stream error: $e'),
      );

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      _scanDoneSub = FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && state.status == BleStatus.scanning) {
          state = state.copyWith(status: BleStatus.idle);
          if (!connecting) {
            _log(BleLogKind.sys, 'Quick-connect: no matching device found');
          }
        }
      });
    } catch (e) {
      _setError('quickConnect: $e');
      state = state.copyWith(status: BleStatus.idle);
    }
  }

  // ─── Connect ──────────────────────────────────────────────────────────────

  Future<void> connect(String deviceId) async {
    try {
      if (state.status == BleStatus.scanning) await stopScan();

      state = state.copyWith(status: BleStatus.connecting, clearError: true);
      _log(BleLogKind.sys, 'Connecting to $deviceId…');

      final device = BluetoothDevice.fromId(deviceId);
      _device = device;

      // Listen for unexpected disconnection while connected
      _connSub?.cancel();
      _connSub = device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected &&
            state.status == BleStatus.connected) {
          _cleanupNotifySubscriptions();
          _writeChar = null;
          state = state.copyWith(
            status: BleStatus.idle,
            canSend: false,
            clearConnected: true,
          );
          _log(BleLogKind.sys, 'Device disconnected unexpectedly');
        }
      });

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 35),
      );

      final services = await device.discoverServices();

      // Bump MTU so the ~24-byte EMG4: line fits in one notification
      // (default BLE payload is 20 bytes). Best-effort — not fatal if refused.
      try {
        await device.requestMtu(64);
      } catch (_) {}

      // ── Service/characteristic discovery ────────────────────────────────

      BluetoothCharacteristic? writeChar;
      final notifyChars = <BluetoothCharacteristic>[];
      bool usedNus = false;

      // Prefer Nordic UART Service
      final nusServiceGuid = Guid(_nusService);
      final nusWriteGuid   = Guid(_nusWrite);
      final nusNotifyGuid  = Guid(_nusNotify);

      final nusSvc = services.where((s) => s.uuid == nusServiceGuid).firstOrNull;
      if (nusSvc != null) {
        usedNus = true;
        for (final c in nusSvc.characteristics) {
          if (c.uuid == nusWriteGuid)  writeChar = c;
          if (c.uuid == nusNotifyGuid) notifyChars.add(c);
        }
      }

      // Fallback: first writable char + all notifiable chars across all services
      if (!usedNus) {
        for (final svc in services) {
          for (final c in svc.characteristics) {
            if (writeChar == null &&
                (c.properties.write || c.properties.writeWithoutResponse)) {
              writeChar = c;
            }
            if (c.properties.notify || c.properties.indicate) {
              notifyChars.add(c);
            }
          }
        }
      }

      // ── Subscribe to notify characteristics ─────────────────────────────

      _cleanupNotifySubscriptions();
      for (final c in notifyChars) {
        await c.setNotifyValue(true);
        _notifySubs.add(c.onValueReceived.listen((bytes) {
          String decoded;
          try {
            decoded = utf8.decode(bytes);
          } catch (_) {
            decoded = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          }
          _log(BleLogKind.rx, decoded);
          _incoming.add(decoded.trim());
        }));
      }

      _writeChar = writeChar;

      final label = usedNus
          ? '1 write + ${notifyChars.length} notify char (NUS)'
          : '${writeChar != null ? 1 : 0} write + ${notifyChars.length} notify char';

      final displayName =
          device.platformName.isNotEmpty ? device.platformName : deviceId;

      state = state.copyWith(
        status: BleStatus.connected,
        connectedId: deviceId,
        connectedName: displayName,
        canSend: writeChar != null,
      );
      _log(BleLogKind.sys, 'Connected: $label');
    } catch (e) {
      _setError('connect: $e');
      _cleanupNotifySubscriptions();
      _writeChar = null;
      state = state.copyWith(
        status: BleStatus.idle,
        canSend: false,
        clearConnected: true,
      );
    }
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    try {
      _cleanupNotifySubscriptions();
      _connSub?.cancel();
      _connSub = null;
      _writeChar = null;

      final device = _device;
      _device = null;

      if (device != null && device.isConnected) {
        await device.disconnect();
      }

      state = state.copyWith(
        status: BleStatus.idle,
        canSend: false,
        clearConnected: true,
      );
      _log(BleLogKind.sys, 'Disconnected');
    } catch (e) {
      _setError('disconnect: $e');
    }
  }

  // ─── Send ─────────────────────────────────────────────────────────────────

  Future<void> send(String text) async {
    try {
      final writeChar = _writeChar;
      if (writeChar == null || !state.canSend) {
        _setError('No writable characteristic — connect first');
        return;
      }

      // Append '\n' (0x0A) for ESP32 line-based parsing
      final bytes = [...utf8.encode(text), 0x0A];

      // Prefer write-with-response when available; fall back to writeWithoutResponse
      final withoutResponse =
          writeChar.properties.writeWithoutResponse && !writeChar.properties.write;

      await writeChar.write(bytes, withoutResponse: withoutResponse);
      _log(BleLogKind.tx, text);
    } catch (e) {
      _setError('send: $e');
    }
  }

  // ─── Log ──────────────────────────────────────────────────────────────────

  void clearLog() {
    state = state.copyWith(log: []);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _cleanupNotifySubscriptions() {
    for (final sub in _notifySubs) {
      sub.cancel();
    }
    _notifySubs.clear();
  }
}

// ─── Board name matching (suffix contract) ────────────────────────────────────

// Each board derives a random-looking BLE name from its own chip MAC, with a
// fixed side suffix so the app can pair reliably regardless of the random
// part: "Kinex-<HEX>-H" (hand), "Kinex-<HEX>-L" (leg-L), "Kinex-<HEX>-R"
// (leg-R). Matching is done on the SUFFIX of the trimmed, lowercased name —
// not a plain "contains" — so a stray "l"/"r"/"h" inside the random hex token
// can't cause a false match. Old boards not yet reflashed with the MAC-based
// name still advertise the fixed legacy names ("Kinex-EMG", "Kinex-Hand"), so
// each matcher also accepts those for backward compatibility.
//
// The legacy fallbacks are only consulted when the name carries NO explicit
// side suffix. Without that guard "Kinex-EMG-R" would match the Leg-L matcher
// via its "emg" substring and quickConnect could bind the right board to the
// left slot.
bool _hasSideSuffix(String lowerName) =>
    lowerName.endsWith('-l') ||
    lowerName.endsWith('-r') ||
    lowerName.endsWith('-h');

bool matchesHandBoard(String lowerName) =>
    lowerName.contains('kinex') &&
    (lowerName.endsWith('-h') ||
        (!_hasSideSuffix(lowerName) && lowerName.contains('hand')));

bool matchesLegLBoard(String lowerName) =>
    lowerName.contains('kinex') &&
    (lowerName.endsWith('-l') ||
        (!_hasSideSuffix(lowerName) && lowerName.contains('emg')));

bool matchesLegRBoard(String lowerName) =>
    lowerName.contains('kinex') && lowerName.endsWith('-r');

// ─── Provider ────────────────────────────────────────────────────────────────

// Three independent board slots, each its own BLE connection. flutter_blue_plus
// keeps multiple devices connected at once, so all three can be live together
// — or any subset alone. [bleControllerProvider] is the Leg-L board (kept
// under its original name so existing EMG screens are unchanged — the single
// legacy "Kinex-EMG" board pairs here too, see [matchesLegLBoard]); the Hand
// board (MPU6050 tilt) uses [handBleProvider]; the Leg-R board uses
// [legRBleProvider]. They share the global BLE scanner, so the Devices page
// connects them one at a time (it disables a board's button while any other
// board is scanning/connecting).
final bleControllerProvider =
    NotifierProvider<BleController, BleState>(BleController.new);

final handBleProvider =
    NotifierProvider<BleController, BleState>(BleController.new);

final legRBleProvider =
    NotifierProvider<BleController, BleState>(BleController.new);
