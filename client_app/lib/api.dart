import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class VaultApi {
  VaultApi._();
  static final instance = VaultApi._();
  final _db = FirebaseFirestore.instance;
  final _random = Random.secure();
  bool _seeded = false;

  static const _catalog = <String, Map<String, Object>>{
    'step_ladder': {'name': '4-step safety ladder', 'rate': 2.0, 'count': 2},
    'cordless_drill': {
      'name': 'Cordless drill-driver kit',
      'rate': 3.0,
      'count': 3
    },
    'wet_dry_vacuum': {'name': 'Wet & dry vacuum', 'rate': 4.0, 'count': 2},
    'carpet_cleaner': {
      'name': 'Carpet & upholstery cleaner',
      'rate': 5.0,
      'count': 1
    },
    'pressure_washer': {
      'name': 'Adjustable pressure washer',
      'rate': 5.0,
      'count': 1
    },
    'steam_cleaner': {
      'name': 'Household steam cleaner',
      'rate': 4.0,
      'count': 1
    },
    'hand_truck': {'name': 'Folding hand truck', 'rate': 2.0, 'count': 2},
    'furniture_kit': {'name': 'Furniture moving kit', 'rate': 2.0, 'count': 1},
    'laser_measure': {
      'name': 'Laser distance measurer',
      'rate': 2.0,
      'count': 1
    },
    'laser_level': {
      'name': 'Self-leveling laser level',
      'rate': 3.0,
      'count': 1
    },
    'stud_finder': {
      'name': 'Wall stud & wire detector',
      'rate': 2.0,
      'count': 1
    },
    'workbench': {'name': 'Folding workbench', 'rate': 2.0, 'count': 1},
    'drain_auger': {'name': 'Manual drain auger', 'rate': 2.0, 'count': 1},
    'dehumidifier': {'name': 'Portable dehumidifier', 'rate': 3.0, 'count': 1},
    'window_kit': {
      'name': 'Ground-reach window cleaning kit',
      'rate': 2.0,
      'count': 1
    },
  };

  Future<void> _ready() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw const ApiFailure(
          'Firebase sign-in is not ready. Enable Anonymous sign-in in Firebase Authentication.');
    }
    if (_seeded) return;
    for (final entry in _catalog.entries) {
      final ref = _db.collection('tools').doc(entry.key);
      final snap = await ref.get();
      if (!snap.exists) {
        final count = entry.value['count']! as int;
        await ref.set({
          'name': entry.value['name'],
          'hourly_rate': entry.value['rate'],
          'total_units': count,
          'available_assets': List.generate(
              count, (i) => 'ASSET${(i + 1).toString().padLeft(2, '0')}'),
          'updated_at': Timestamp.now(),
        });
      }
    }
    _seeded = true;
  }

  String _error(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Firestore denied access. Enable Anonymous sign-in and apply the demo rules from the README.';
    }
    return 'Firebase error (${e.code}): ${e.message ?? 'request failed'}';
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _public(Map<String, dynamic> data) {
    final now = DateTime.now();
    final picked = _date(data['picked_up_at']);
    final returned = _date(data['returned_at']);
    final elapsed = picked == null
        ? 0
        : max(
            0,
            ((returned ?? now).difference(picked).inMilliseconds / 1000)
                .floor());
    final hours = max(1, (elapsed + 3599) ~/ 3600);
    final expires = _date(data['pickup_expires_at']);
    var status = data['status']?.toString() ?? 'reserved';
    if (status == 'reserved' && expires != null && now.isAfter(expires))
      status = 'expired';
    return {
      ...data,
      'status': status,
      'reserved_at': _date(data['reserved_at'])?.toIso8601String(),
      'pickup_expires_at': expires?.toIso8601String(),
      'picked_up_at': picked?.toIso8601String(),
      'returned_at': returned?.toIso8601String(),
      'elapsed_seconds': elapsed,
      'charge_hours': hours,
      'rental_fee': double.parse(
          (hours * ((data['hourly_rate'] as num?)?.toDouble() ?? 0))
              .toStringAsFixed(2)),
    };
  }

  Future<void> _expireReservations() async {
    final snapshots = await _db
        .collection('reservations')
        .where('status', isEqualTo: 'reserved')
        .get();
    final now = DateTime.now();
    for (final reservation in snapshots.docs) {
      final d = reservation.data();
      final expires = _date(d['pickup_expires_at']);
      if (expires == null || now.isBefore(expires)) continue;
      final toolRef = _db.collection('tools').doc(d['tool_id'].toString());
      await _db.runTransaction((tx) async {
        final current = await tx.get(reservation.reference);
        final tool = await tx.get(toolRef);
        if (!current.exists ||
            !tool.exists ||
            current.data()?['status'] != 'reserved') return;
        final assets =
            List<String>.from(tool.data()?['available_assets'] ?? const []);
        final asset = current.data()?['asset_id']?.toString();
        if (asset != null && !assets.contains(asset)) assets.add(asset);
        tx.update(toolRef,
            {'available_assets': assets, 'updated_at': Timestamp.now()});
        tx.update(reservation.reference, {'status': 'expired'});
      });
    }
  }

  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, Object?>? body}) async {
    try {
      await _ready();
      final cleanPath = path.split('?').first;
      if (method == 'GET' && cleanPath == '/api/tools') {
        await _expireReservations();
        final docs = await _db.collection('tools').get();
        final items = docs.docs.map((d) {
          final data = d.data();
          final assets =
              List<String>.from(data['available_assets'] ?? const []);
          return {
            'id': d.id,
            'name': data['name'],
            'hourly_rate': data['hourly_rate'],
            'available': assets.length,
            'total_units': data['total_units'] ?? assets.length
          };
        }).toList()
          ..sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
        return {'tools': items};
      }
      if (method == 'GET' && cleanPath == '/api/reservations') {
        await _expireReservations();
        final resident =
            Uri.parse('https://vault.local$path').queryParameters['resident'] ??
                '';
        final docs = await _db
            .collection('reservations')
            .where('resident', isEqualTo: resident)
            .get();
        final items = docs.docs
            .map((d) => _public({'id': d.id, ...d.data()}))
            .toList()
          ..sort((a, b) => (b['reserved_at'] ?? '')
              .toString()
              .compareTo((a['reserved_at'] ?? '').toString()));
        return {'reservations': items};
      }
      if (method == 'GET' && cleanPath.startsWith('/api/reservations/')) {
        final id = cleanPath.split('/').last;
        final doc = await _db.collection('reservations').doc(id).get();
        if (!doc.exists) throw const ApiFailure('Reservation not found.');
        return {
          'reservation': _public({'id': doc.id, ...doc.data()!})
        };
      }
      if (method != 'POST')
        throw const ApiFailure('Unsupported Firebase request.');
      final data = body ?? const <String, Object?>{};
      if (cleanPath == '/api/reservations')
        return {'reservation': await _reserve(data)};
      if (cleanPath == '/api/locker/pickup')
        return {'reservation': await _pickup(data)};
      if (cleanPath == '/api/locker/return')
        return {'reservation': await _startReturn(data)};
      if (cleanPath == '/api/locker/return-sensor')
        return {'reservation': await _finishReturn(data)};
      if (cleanPath == '/api/payment')
        return {
          'reservation': await _pay(data),
          'message': 'Demo payment approved.'
        };
      throw const ApiFailure('Unknown Tool Vault action.');
    } on ApiFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ApiFailure(_error(e));
    } catch (e) {
      throw ApiFailure('Could not complete the Firebase action: $e');
    }
  }

  Future<Map<String, dynamic>> _reserve(Map<String, Object?> input) async {
    await _expireReservations();
    final toolId = input['tool_id']?.toString() ?? '';
    final toolRef = _db.collection('tools').doc(toolId);
    final reservationRef = _db.collection('reservations').doc();
    final pin = _random.nextInt(1000000).toString().padLeft(6, '0');
    final result = await _db.runTransaction<Map<String, dynamic>>((tx) async {
      final tool = await tx.get(toolRef);
      if (!tool.exists) throw const ApiFailure('Choose a listed tool.');
      final data = tool.data()!;
      final assets = List<String>.from(data['available_assets'] ?? const []);
      if (assets.isEmpty)
        throw const ApiFailure(
            'This tool is currently reserved or checked out.');
      final asset = assets.removeAt(0);
      final now = DateTime.now();
      final rate = (data['hourly_rate'] as num).toDouble();
      final reservation = <String, dynamic>{
        'resident': input['resident']?.toString() ?? '',
        'unit': input['unit']?.toString() ?? '',
        'tool_id': toolId,
        'tool_name': data['name'],
        'hourly_rate': rate,
        'asset_id': asset,
        'pin': pin,
        'pickup_qr': 'TVPICKUP|${reservationRef.id}|$toolId|$pin',
        'barcode': 'TVITEM|VILLAS01|$toolId|$asset',
        'status': 'reserved',
        'reserved_at': Timestamp.fromDate(now),
        'pickup_expires_at':
            Timestamp.fromDate(now.add(const Duration(hours: 1))),
        'picked_up_at': null,
        'returned_at': null,
        'paid': false,
        'owner_uid': FirebaseAuth.instance.currentUser!.uid,
      };
      tx.update(
          toolRef, {'available_assets': assets, 'updated_at': Timestamp.now()});
      tx.set(reservationRef, reservation);
      return _public({'id': reservationRef.id, ...reservation});
    });
    return result;
  }

  Future<Map<String, dynamic>> _findReservation(
      String field, Object value) async {
    final result = await _db
        .collection('reservations')
        .where(field, isEqualTo: value)
        .limit(1)
        .get();
    if (result.docs.isEmpty)
      throw const ApiFailure(
          'PIN or QR is not linked to an active reservation.');
    final doc = result.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  Future<Map<String, dynamic>> _pickup(Map<String, Object?> input) async {
    final pin = input['pin']?.toString().trim() ?? '';
    final qr = input['qr']?.toString().trim() ?? '';
    if (pin.isEmpty && qr.isEmpty)
      throw const ApiFailure('Enter the pickup PIN or QR.');
    final found = await _findReservation(
        pin.isNotEmpty ? 'pin' : 'pickup_qr', pin.isNotEmpty ? pin : qr);
    final ref = _db.collection('reservations').doc(found['id'].toString());
    final updated = await _db.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw const ApiFailure('Reservation not found.');
      final current = snap.data()!;
      if (current['status'] != 'reserved')
        throw const ApiFailure('Reservation expired or already collected.');
      final expiry = _date(current['pickup_expires_at']);
      if (expiry == null || DateTime.now().isAfter(expiry))
        throw const ApiFailure('Reservation expired or already collected.');
      final now = Timestamp.now();
      tx.update(ref, {'status': 'borrowed', 'picked_up_at': now});
      return _public({
        'id': ref.id,
        ...current,
        'status': 'borrowed',
        'picked_up_at': now
      });
    });
    return updated;
  }

  Future<Map<String, dynamic>> _startReturn(Map<String, Object?> input) async {
    final barcode = input['barcode']?.toString().trim() ?? '';
    final docs = await _db
        .collection('reservations')
        .where('barcode', isEqualTo: barcode)
        .get();
    QueryDocumentSnapshot<Map<String, dynamic>>? match;
    for (final doc in docs.docs) {
      if (doc.data()['status'] == 'borrowed') {
        match = doc;
        break;
      }
    }
    if (match == null)
      throw const ApiFailure(
          'Barcode not found, not checked out, or assigned to another tool.');
    final ref = match.reference;
    return _db.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data()?['status'] != 'borrowed')
        throw const ApiFailure('This item is no longer checked out.');
      tx.update(ref, {'status': 'return_scanning'});
      return _public(
          {'id': ref.id, ...snap.data()!, 'status': 'return_scanning'});
    });
  }

  Future<Map<String, dynamic>> _finishReturn(Map<String, Object?> input) async {
    final ref =
        _db.collection('reservations').doc(input['reservation_id']?.toString());
    return _db.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists ||
          snap.data()?['status'] != 'return_scanning' ||
          input['dark_confirmed'] != true) {
        throw const ApiFailure(
            'A verified return and occupancy-sensor confirmation are required.');
      }
      final data = snap.data()!;
      final toolRef = _db.collection('tools').doc(data['tool_id'].toString());
      final tool = await tx.get(toolRef);
      final assets =
          List<String>.from(tool.data()?['available_assets'] ?? const []);
      final asset = data['asset_id']?.toString();
      if (asset != null && !assets.contains(asset)) assets.add(asset);
      final now = Timestamp.now();
      tx.update(toolRef, {'available_assets': assets, 'updated_at': now});
      tx.update(ref, {'status': 'returned', 'returned_at': now});
      return _public(
          {'id': ref.id, ...data, 'status': 'returned', 'returned_at': now});
    });
  }

  Future<Map<String, dynamic>> _pay(Map<String, Object?> input) async {
    final id = input['reservation_id']?.toString() ?? '';
    final ref = _db.collection('reservations').doc(id);
    return _db.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data()?['status'] != 'returned')
        throw const ApiFailure('Return the tool before paying.');
      final data = snap.data()!;
      if (data['paid'] == true)
        throw const ApiFailure('This rental is already paid.');
      final method = input['method']?.toString() ?? '';
      if (!['Card', 'FPX online banking', "Touch 'n Go eWallet"]
          .contains(method)) throw const ApiFailure('Select a payment method.');
      String? last4;
      if (method == 'Card') {
        final digits = (input['card_number']?.toString() ?? '')
            .replaceAll(RegExp(r'\D'), '');
        final expiry = input['expiry']?.toString() ?? '';
        final parts = expiry.split('/');
        var valid = false;
        if (parts.length == 2) {
          final month = int.tryParse(parts[0]) ?? 0;
          var year = int.tryParse(parts[1]) ?? 0;
          if (year < 100) year += 2000;
          final now = DateTime.now();
          valid = month >= 1 &&
              month <= 12 &&
              (year > now.year || (year == now.year && month >= now.month));
        }
        final cvv = input['cvv']?.toString() ?? '';
        if (digits != '4242424242424242' ||
            !valid ||
            !RegExp(r'^\d{3}$').hasMatch(cvv)) {
          throw const ApiFailure(
              'For this demo only, use card 4242 4242 4242 4242, a future expiry and any 3-digit CVV.');
        }
        last4 = digits.substring(digits.length - 4);
      }
      tx.update(ref, {
        'paid': true,
        'payment_method': method,
        'last4': last4,
        'paid_at': Timestamp.now()
      });
      return _public({
        'id': ref.id,
        ...data,
        'paid': true,
        'payment_method': method,
        'last4': last4
      });
    });
  }

  Future<void> submitReport(
      {required String kind,
      required String comment,
      required List<XFile> attachments}) async {
    try {
      await _ready();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final urls = <Map<String, String>>[];
      for (final file in attachments) {
        final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final ref = FirebaseStorage.instance.ref(
            'support_reports/$uid/${DateTime.now().microsecondsSinceEpoch}_$safeName');
        await ref.putData(await file.readAsBytes(),
            SettableMetadata(contentType: file.mimeType));
        urls.add({
          'name': file.name,
          'url': await ref.getDownloadURL(),
          'type': file.mimeType ?? 'file'
        });
      }
      await _db.collection('support_reports').add({
        'resident': FirebaseAuth.instance.currentUser!.uid,
        'type': kind,
        'comment': comment.trim(),
        'attachments': urls,
        'created_at': Timestamp.now(),
        'status': 'new',
      });
    } on FirebaseException catch (e) {
      throw ApiFailure(_error(e));
    }
  }
}
