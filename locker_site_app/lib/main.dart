import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
    runApp(const LockerKioskApp());
  } catch (error) {
    runApp(FirebaseStartupErrorApp(error: error.toString()));
  }
}

class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({super.key, required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          backgroundColor: paper,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOOL VAULT KIOSK',
                        style: TextStyle(
                            color: red,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    const Text('Firebase setup is incomplete',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Enable Authentication → Sign-in method → Anonymous in Firebase Console, then restart this app.'),
                    const SizedBox(height: 16),
                    SelectableText(error,
                        style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

const red = Color(0xFF9E1B32),
    ink = Color(0xFF252426),
    muted = Color(0xFF777477),
    paper = Color(0xFFF7F6F3),
    green = Color(0xFF287A47);

class LockerKioskApp extends StatelessWidget {
  const LockerKioskApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(seedColor: red, primary: red),
        ),
        home: const KioskPage(),
      );
}

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});
  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  final entry = TextEditingController();
  final scanner = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String mode = 'idle';
  String? message;
  Map<String, dynamic>? unlocked;
  bool busy = false, scanning = false;
  @override
  void dispose() {
    entry.dispose();
    scanner.dispose();
    super.dispose();
  }

  Future<void> verify(String value) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await scanner.stop();
      final path =
          mode == 'pickup' ? '/api/locker/pickup' : '/api/locker/return';
      final body = mode == 'pickup'
          ? (value.trim().startsWith('TVPICKUP|')
              ? {'qr': value.trim()}
              : {'pin': value.trim()})
          : {'barcode': value.trim()};
      final result = await VaultApi.instance.request('POST', path, body: body);
      if (!mounted) return;
      setState(() {
        unlocked = Map<String, dynamic>.from(result['reservation'] as Map);
        message = null;
        scanning = false;
        entry.clear();
      });
    } on ApiFailure catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted)
        setState(() => message = 'Could not verify this code. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirmReturn() async {
    final current = unlocked;
    if (busy || current == null) return;
    setState(() => busy = true);
    try {
      final done = await VaultApi.instance.request(
        'POST',
        '/api/locker/return-sensor',
        body: {'reservation_id': current['id'], 'dark_confirmed': true},
      );
      if (mounted)
        setState(() =>
            unlocked = Map<String, dynamic>.from(done['reservation'] as Map));
    } on ApiFailure catch (e) {
      if (mounted) setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void changeMode(String value) {
    scanner.stop();
    setState(() {
      mode = value;
      unlocked = null;
      entry.clear();
      message = null;
      scanning = false;
    });
  }

  void onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw != null && raw.isNotEmpty) {
        verify(raw);
        return;
      }
    }
  }

  Future<void> openScanner() async {
    setState(() => scanning = true);
    try {
      await scanner.start();
    } on MobileScannerException catch (e) {
      if (mounted)
        setState(() {
          scanning = false;
          message =
              'Camera permission/device error (${e.errorCode.name}). You can type the code instead.';
        });
    } catch (_) {
      if (mounted)
        setState(() {
          scanning = false;
          message = 'Camera unavailable. Type the code instead.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF202124),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                color: red,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOOL VAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'SELF-SERVICE LOCKER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: mode == 'idle'
                        ? _idlePanel()
                        : unlocked == null
                            ? _entryPanel()
                            : mode == 'return' &&
                                    unlocked!['status'] == 'return_scanning'
                                ? _entryPanel()
                                : _unlockedPanel(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'NEIGHBOURHOOD TOOL LIBRARY · ASSISTANCE AVAILABLE IN APP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  Widget _entryPanel() => Card(
        margin: const EdgeInsets.all(18),
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Icon(Icons.door_sliding_outlined, color: red, size: 52),
              const SizedBox(height: 6),
              const Text(
                'WELCOME TO THE VAULT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Scan a pickup pass or return the original tool.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'pickup',
                    label: Text('PICK UP'),
                    icon: Icon(Icons.output),
                  ),
                  ButtonSegment(
                    value: 'return',
                    label: Text('RETURN'),
                    icon: Icon(Icons.keyboard_return),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (v) => changeMode(v.first),
              ),
              const SizedBox(height: 14),
              if (scanning)
                SizedBox(
                  height: 210,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MobileScanner(
                      controller: scanner,
                      onDetect: onDetect,
                      errorBuilder: (context, e) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Camera error ${e.errorCode.name}',
                              style: const TextStyle(color: red),
                            ),
                            TextButton(
                              onPressed: () {
                                scanner.stop();
                                setState(() {
                                  scanning = false;
                                  message = 'Type the code below to continue.';
                                });
                              },
                              child: const Text('ENTER CODE MANUALLY'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (!scanning)
                TextField(
                  controller: entry,
                  keyboardType: mode == 'pickup'
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: mode == 'pickup'
                        ? 'Enter six-digit pickup PIN'
                        : 'Scan or type tool barcode',
                    hintText: mode == 'return'
                        ? 'TVITEM|VILLAS01|tool_id|ASSET01'
                        : null,
                    prefixIcon: Icon(
                      mode == 'pickup' ? Icons.password : Icons.qr_code_2,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => verify(v),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : openScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('SCAN QR / BARCODE'),
                    ),
                  ),
                  if (scanning) const SizedBox(width: 8),
                  if (scanning)
                    IconButton(
                      onPressed: () {
                        scanner.stop();
                        setState(() => scanning = false);
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => verify(entry.text),
                  style: FilledButton.styleFrom(backgroundColor: red),
                  icon: Icon(mode == 'pickup' ? Icons.lock_open : Icons.search),
                  label: Text(
                    busy
                        ? 'VERIFYING…'
                        : mode == 'pickup'
                            ? 'VERIFY PASS & OPEN LINKED LOCKER'
                            : 'VERIFY ITEM & OPEN LOCKER',
                  ),
                ),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: red, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                mode == 'pickup'
                    ? 'The pickup PIN or QR identifies the reserved tool and assigned locker. No tool selection is needed.'
                    : 'Only the original barcode for a currently borrowed tool can open its return locker.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),
              if (mode == 'return' &&
                  unlocked?['status'] == 'return_scanning') ...[
                const SizedBox(height: 14),
                OccupancySensorCard(
                    reservation: unlocked!, onConfirm: confirmReturn),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => changeMode('idle'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('BACK TO WELCOME SCREEN'),
              ),
            ],
          ),
        ),
      );

  Widget _idlePanel() => Card(
        margin: const EdgeInsets.all(18),
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handyman_outlined, color: red, size: 58),
              const SizedBox(height: 12),
              const Text('HI, BORROW ANY TOOLS?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ink, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                  'Choose what you need to do. Your resident app reservation will identify the right locker.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.45)),
              const SizedBox(height: 22),
              SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                      onPressed: () => changeMode('pickup'),
                      style: FilledButton.styleFrom(backgroundColor: red),
                      icon: const Icon(Icons.output),
                      label: const Text('PICK UP A RESERVED TOOL'))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                      onPressed: () => changeMode('return'),
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('RETURN A TOOL'))),
            ],
          ),
        ),
      );
  Widget _unlockedPanel() {
    final r = unlocked!;
    final returned = r['status'] == 'returned';
    return Card(
      margin: const EdgeInsets.all(18),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              returned ? Icons.sensor_door_outlined : Icons.lock_open,
              color: green,
              size: 64,
            ),
            Text(
              returned ? 'RETURN CONFIRMED' : 'LOCKER UNLOCKED',
              style: const TextStyle(
                color: green,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'LOCKER · ${r['tool_id'].toString().toUpperCase()}',
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              r['tool_name'].toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            Text(
              returned
                  ? 'The dark camera reading confirmed the original tool is inside. Return is complete.'
                  : 'Take the reserved item and close the locker. The resident timer starts now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.4),
            ),
            if (returned)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Rental charge: RM ${(r['rental_fee'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: red,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => setState(() {
                  unlocked = null;
                  mode = 'idle';
                }),
                style: FilledButton.styleFrom(backgroundColor: red),
                child: const Text('READY FOR NEXT RESIDENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OccupancySensorCard extends StatefulWidget {
  const OccupancySensorCard(
      {super.key, required this.reservation, required this.onConfirm});
  final Map<String, dynamic> reservation;
  final Future<void> Function() onConfirm;
  @override
  State<OccupancySensorCard> createState() => _OccupancySensorCardState();
}

class _OccupancySensorCardState extends State<OccupancySensorCard> {
  CameraController? camera;
  String? error;
  double light = 120;
  bool dark = false, submitting = false, done = false;
  int darkFrames = 0;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) startCamera();
  }

  Future<void> startCamera() async {
    try {
      setState(() => error = null);
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('No camera found');
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final c = CameraController(back, ResolutionPreset.low,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      camera = c;
      await c.initialize();
      await c.startImageStream(onFrame);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = 'Camera unavailable: $e');
    }
  }

  void onFrame(CameraImage image) {
    final bytes = image.planes.first.bytes;
    if (bytes.isEmpty) return;
    var total = 0, n = 0;
    final step = (bytes.length ~/ 800).clamp(1, 100000).toInt();
    for (var i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      n++;
    }
    final avg = total / n;
    final isDark = avg < 24;
    darkFrames = isDark ? darkFrames + 1 : 0;
    if (mounted && ((avg - light).abs() > 3 || isDark != dark)) {
      setState(() {
        light = avg;
        dark = isDark;
      });
    }
    if (darkFrames >= 8 && !submitting && !done) confirm();
  }

  Future<void> simulateDark() async {
    if (submitting || done) return;
    setState(() {
      dark = true;
      light = 5;
      error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await confirm();
  }

  Future<void> confirm() async {
    if (!dark || submitting || done) return;
    setState(() => submitting = true);
    try {
      if (camera?.value.isStreamingImages == true)
        await camera!.stopImageStream();
      await widget.onConfirm();
      if (mounted) setState(() => done = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final initialized = camera?.value.isInitialized == true;
    return Card(
      color: const Color(0xFFF7F6F3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('RETURN SENSOR · ${r['tool_name']}',
                style:
                    const TextStyle(color: ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 132,
                child: kIsWeb
                    ? Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Colors.white70, size: 30),
                              SizedBox(height: 4),
                              Text('OCCUPANCY CAMERA SIMULATION',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800))
                            ]))
                    : initialized
                        ? CameraPreview(camera!)
                        : Container(
                            color: Colors.black,
                            alignment: Alignment.center,
                            child: error == null
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.videocam_off,
                                    color: Colors.white70, size: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: done || dark
                      ? const Color(0xFFE8F3EA)
                      : const Color(0xFFFFF5E7),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(
                    done
                        ? Icons.check_circle
                        : dark
                            ? Icons.dark_mode
                            : Icons.wb_sunny_outlined,
                    color: done || dark ? green : red),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        done
                            ? 'ITEM RETURNED'
                            : dark
                                ? 'DARK · ITEM DETECTED'
                                : 'LIGHT · WAITING FOR ITEM',
                        style: TextStyle(
                            color: done || dark ? green : red,
                            fontWeight: FontWeight.w900))),
                Text('${light.toStringAsFixed(0)} / 255',
                    style: const TextStyle(color: muted, fontSize: 11))
              ]),
            ),
            if (kIsWeb || error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: done || submitting ? null : simulateDark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(submitting
                      ? 'CONFIRMING RETURN…'
                      : done
                          ? 'RETURN CONFIRMED'
                          : 'SIMULATE DARK SENSOR READING'),
                ),
              ),
            if (error != null)
              Text(error!, style: const TextStyle(color: red, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
                kIsWeb
                    ? 'Web preview uses a safe sensor simulation. Press the button to represent the locker closing and becoming dark.'
                    : 'Close the locker around the returned item. A sustained dark camera reading confirms the return automatically.',
                style:
                    const TextStyle(color: muted, fontSize: 11, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
