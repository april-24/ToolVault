import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
    runApp(const ToolVaultApp());
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
                    const Text('TOOL VAULT',
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
    border = Color(0xFFE8E4DF);
String rm(num n) => 'RM ${n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2)}';
String dateTime(dynamic value) {
  if (value == null) return '—';
  final d = DateTime.parse(value.toString()).toLocal();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day}/${d.month} $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}

String elapsed(int s) =>
    '${s ~/ 3600}h ${((s ~/ 60) % 60).toString().padLeft(2, '0')}m';

class DemoUser {
  const DemoUser(this.name, this.email, this.password, this.unit);
  final String name, email, password, unit;
}

const demoUsers = [
  DemoUser('Aina Rahman', 'aina@toolvault.demo', 'Aina123!', 'V-08-12'),
  DemoUser('Jason Tan', 'jason@toolvault.demo', 'Jason123!', 'V-03-05'),
  DemoUser('Priya Kumar', 'priya@toolvault.demo', 'Priya123!', 'V-11-02'),
];

class VaultTool {
  const VaultTool(
    this.id,
    this.name,
    this.category,
    this.description,
    this.safety,
    this.icon,
    this.rate,
  );
  final String id, name, category, description, safety;
  final IconData icon;
  final double rate;
  String get barcode => 'TVITEM|VILLAS01|$id|ASSET01';
}

const tools = <VaultTool>[
  VaultTool(
    'step_ladder',
    '4-step safety ladder',
    'Home repair',
    'A sturdy ladder for shelves, curtains and ceiling fixtures.',
    'Set on firm, level ground. Lock spreaders, face the ladder and keep three points of contact. Never stand on the top step.',
    Icons.stairs,
    2,
  ),
  VaultTool(
    'cordless_drill',
    'Cordless drill-driver kit',
    'Home repair',
    'A compact drill-driver with common household bits.',
    'Wear eye protection, secure work and use the correct bit. Do not drill near wiring or plumbing.',
    Icons.handyman,
    3,
  ),
  VaultTool(
    'wet_dry_vacuum',
    'Wet & dry vacuum',
    'Cleaning',
    'A compact vacuum for small spills, dust and cleanup.',
    'Use the correct mode. Unplug before emptying. Do not vacuum hot ash or flammable liquids.',
    Icons.cleaning_services,
    4,
  ),
  VaultTool(
    'carpet_cleaner',
    'Carpet & upholstery cleaner',
    'Cleaning',
    'A portable extractor for rugs, sofas and car seats.',
    'Test a hidden patch first. Use recommended solution only.',
    Icons.weekend,
    5,
  ),
  VaultTool(
    'pressure_washer',
    'Adjustable pressure washer',
    'Garden',
    'A consumer pressure washer for patios and outdoor furniture.',
    'Start at low pressure. Never point at people, pets, electrical gear or fragile surfaces.',
    Icons.water,
    5,
  ),
  VaultTool(
    'steam_cleaner',
    'Household steam cleaner',
    'Cleaning',
    'A small steam cleaner for sealed floors and grout.',
    'Steam can burn. Let the unit cool before refilling. Keep the nozzle away from people and pets.',
    Icons.air,
    4,
  ),
  VaultTool(
    'hand_truck',
    'Folding hand truck',
    'Moving',
    'A compact trolley for boxes and small appliances.',
    'Keep loads within the printed limit and strap them securely.',
    Icons.local_shipping_outlined,
    2,
  ),
  VaultTool(
    'furniture_kit',
    'Furniture moving kit',
    'Moving',
    'Lifter and floor-safe sliders for rearranging furniture.',
    'Use on suitable flat floors. Keep fingers clear and move heavy items with another person.',
    Icons.chair_alt_outlined,
    2,
  ),
  VaultTool(
    'laser_measure',
    'Laser distance measurer',
    'Home repair',
    'A handheld digital measurer for rooms and furniture.',
    'Never look into its laser aperture or point it at anyone.',
    Icons.straighten,
    2,
  ),
  VaultTool(
    'laser_level',
    'Self-leveling laser level',
    'Home repair',
    'A line laser for aligning shelves and picture frames.',
    'Do not look into the beam. Use the supplied mount and keep away from children.',
    Icons.square_foot,
    3,
  ),
  VaultTool(
    'stud_finder',
    'Wall stud & wire detector',
    'Home repair',
    'A wall scanner to locate studs and flag possible wiring.',
    'A detector cannot guarantee a wall is safe to drill. Avoid outlets and pipes.',
    Icons.sensors,
    2,
  ),
  VaultTool(
    'workbench',
    'Folding workbench',
    'Home repair',
    'A portable clamping bench for light DIY and assembly.',
    'Lock legs and clamps. Do not exceed load rating or use as a seat or ladder.',
    Icons.table_restaurant,
    2,
  ),
  VaultTool(
    'drain_auger',
    'Manual drain auger',
    'Home repair',
    'A hand-cranked drain snake for simple household blockages.',
    'Wear gloves and eye protection. Never combine with chemical drain cleaners.',
    Icons.plumbing,
    2,
  ),
  VaultTool(
    'dehumidifier',
    'Portable dehumidifier',
    'Home care',
    'A room-size unit for damp areas and laundry drying.',
    'Keep upright, away from splashes and use a grounded outlet.',
    Icons.device_thermostat,
    3,
  ),
  VaultTool(
    'window_kit',
    'Ground-reach window cleaning kit',
    'Cleaning',
    'A telescopic pole and squeegee for ground-reachable windows.',
    'Use from the ground only. Do not lean out or climb on a ladder or balcony.',
    Icons.window,
    2,
  ),
];

class ToolVaultApp extends StatefulWidget {
  const ToolVaultApp({super.key});
  @override
  State<ToolVaultApp> createState() => _ToolVaultAppState();
}

class _ToolVaultAppState extends State<ToolVaultApp> {
  final navKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  DemoUser? user;
  int tab = 0;
  List<Map<String, dynamic>> inventory = [], rentals = [];
  String? apiError;
  Timer? poll;
  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final u = user;
    if (u == null) return;
    try {
      final x = await Future.wait([
        VaultApi.instance.request('GET', '/api/tools'),
        VaultApi.instance.request(
          'GET',
          '/api/reservations?resident=${Uri.encodeQueryComponent(u.email)}',
        ),
      ]);
      if (!mounted || user?.email != u.email) return;
      setState(() {
        inventory = List<Map<String, dynamic>>.from(x[0]['tools'] as List);
        rentals = List<Map<String, dynamic>>.from(x[1]['reservations'] as List);
        apiError = null;
      });
    } on ApiFailure catch (e) {
      if (mounted) setState(() => apiError = e.message);
    }
  }

  void login(DemoUser u) {
    setState(() {
      user = u;
      tab = 0;
    });
    refresh();
    poll?.cancel();
    poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> reserve(VaultTool t) async {
    try {
      final x = await VaultApi.instance.request(
        'POST',
        '/api/reservations',
        body: {'resident': user!.email, 'unit': user!.unit, 'tool_id': t.id},
      );
      final r = Map<String, dynamic>.from(x['reservation'] as Map);
      if (!mounted) return;
      await refresh();
      await navKey.currentState?.pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => PickupPassPage(id: r['id'].toString()),
        ),
      );
    } on ApiFailure catch (e) {
      if (mounted)
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.message)),
        );
    }
  }

  Future<void> pay(Map<String, dynamic> r, Map<String, Object?> p) async {
    await VaultApi.instance.request(
      'POST',
      '/api/payment',
      body: {'reservation_id': r['id'], ...p},
    );
    await refresh();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navKey,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(seedColor: red, primary: red),
          appBarTheme: const AppBarTheme(
            backgroundColor: paper,
            foregroundColor: ink,
          ),
        ),
        home: user == null
            ? LoginPage(onLogin: login)
            : ResidentHome(
                user: user!,
                tab: tab,
                inventory: inventory,
                rentals: rentals,
                error: apiError,
                onTab: (v) => setState(() => tab = v),
                onRent: reserve,
                onRefresh: refresh,
                onPay: pay,
                onOpenReservation: (r) async {
                  await navKey.currentState?.push<void>(MaterialPageRoute(
                    builder: (_) => PickupPassPage(id: r['id'].toString()),
                  ));
                },
                onLogout: () {
                  poll?.cancel();
                  setState(() => user = null);
                },
              ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});
  final ValueChanged<DemoUser> onLogin;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void signIn() {
    DemoUser? u;
    for (final x in demoUsers) {
      if (x.email == email.text.trim().toLowerCase() &&
          x.password == password.text) u = x;
    }
    if (u == null) {
      setState(
        () => error = 'Email or password did not match a sample account.',
      );
      return;
    }
    widget.onLogin(u);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.handyman_outlined, color: red, size: 54),
                    const SizedBox(height: 10),
                    const Text(
                      'TOOL VAULT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: red,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Shared tools for everyday home projects',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      onSubmitted: (_) => signIn(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Text(error!, style: const TextStyle(color: red)),
                      ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: signIn,
                        child: const Text('SIGN IN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class ResidentHome extends StatelessWidget {
  const ResidentHome({
    super.key,
    required this.user,
    required this.tab,
    required this.inventory,
    required this.rentals,
    required this.error,
    required this.onTab,
    required this.onRent,
    required this.onRefresh,
    required this.onPay,
    required this.onOpenReservation,
    required this.onLogout,
  });
  final DemoUser user;
  final int tab;
  final List<Map<String, dynamic>> inventory, rentals;
  final String? error;
  final ValueChanged<int> onTab;
  final Future<void> Function(VaultTool) onRent;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>, Map<String, Object?>) onPay;
  final Future<void> Function(Map<String, dynamic>) onOpenReservation;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final page = tab == 0
        ? CatalogPage(inventory: inventory, onRent: onRent)
        : tab == 1
            ? RentalsPage(
                rentals: rentals,
                onRefresh: onRefresh,
                onPay: onPay,
                onOpenReservation: onOpenReservation)
            : const HelpPage();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOOL VAULT',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6)),
        backgroundColor: red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          if (error != null)
            Material(
              color: const Color(0xFFFFE5E5),
              child: ListTile(
                leading: const Icon(Icons.cloud_off, color: red),
                title: Text(error!, style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          Expanded(child: page),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: onTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_repair_service_outlined),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'My rentals',
          ),
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'Help'),
        ],
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.inventory, required this.onRent});
  final List<Map<String, dynamic>> inventory;
  final Future<void> Function(VaultTool) onRent;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final search = TextEditingController();
  String category = 'All';
  final categories = const [
    'All',
    'Home repair',
    'Cleaning',
    'Garden',
    'Moving',
    'Home care',
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = tools
        .where(
          (t) =>
              (category == 'All' || t.category == category) &&
              '${t.name} ${t.description}'.toLowerCase().contains(
                    search.text.toLowerCase(),
                  ),
        )
        .toList();
    final stock = {
      for (final r in widget.inventory)
        r['id'].toString(): (r['available'] as num?)?.toInt() ?? 0,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'TOOLS FOR YOUR HOME',
          style: TextStyle(
            fontSize: 23,
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'Shared equipment, charged by the hour.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search tools',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (_) => setState(() => category = c),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 7),
        ...list.map(
          (t) => ToolCard(
            tool: t,
            available: stock[t.id] ?? 0,
            onRent: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      BookingPage(tool: t, onReserve: () => widget.onRent(t)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.available,
    required this.onRent,
  });
  final VaultTool tool;
  final int available;
  final VoidCallback onRent;
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tool.icon, color: red, size: 29),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      tool.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    Text(
                      available > 0
                          ? '${rm(tool.rate)} per hour · $available available'
                          : 'Currently unavailable',
                      style: TextStyle(
                        color: available > 0 ? red : muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: available > 0 ? onRent : null,
                style: FilledButton.styleFrom(backgroundColor: red),
                child: const Text('RENT'),
              ),
            ],
          ),
        ),
      );
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.tool, required this.onReserve});
  final VaultTool tool;
  final Future<void> Function() onReserve;
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool accepted = false, loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('RESERVE TOOL')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.tool.name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            Text(
              '${rm(widget.tool.rate)} per hour · charged for actual time, rounded up to each started hour.',
              style: const TextStyle(color: red, fontWeight: FontWeight.w800),
            ),
            Card(
              color: const Color(0xFFFFF7E2),
              child: ListTile(
                leading:
                    const Icon(Icons.health_and_safety_outlined, color: red),
                title: const Text('Safe-use guidance'),
                subtitle: Text(widget.tool.safety),
              ),
            ),
            const Text(
              'Pick up within one hour. The rental timer starts only when the Locker Site verifies your PIN or QR. The hourly charge is calculated when its return camera confirms the item is back.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            CheckboxListTile(
              value: accepted,
              onChanged: (v) => setState(() => accepted = v ?? false),
              activeColor: red,
              title: const Text(
                'I have read the safe-use guidance.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: accepted && !loading
                    ? () async {
                        setState(() => loading = true);
                        await widget.onReserve();
                        if (mounted) setState(() => loading = false);
                      }
                    : null,
                style: FilledButton.styleFrom(backgroundColor: red),
                child: Text(
                  loading ? 'RESERVING…' : 'RESERVE & GENERATE PICKUP PASS',
                ),
              ),
            ),
          ],
        ),
      );
}

class PickupPassPage extends StatefulWidget {
  const PickupPassPage({super.key, required this.id});
  final String id;
  @override
  State<PickupPassPage> createState() => _PickupPassPageState();
}

class _PickupPassPageState extends State<PickupPassPage> {
  Map<String, dynamic>? r;
  String? error;
  Timer? poll;
  @override
  void initState() {
    super.initState();
    refresh();
    poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final x = await VaultApi.instance.request(
        'GET',
        '/api/reservations/${widget.id}',
      );
      if (mounted)
        setState(() => r = Map<String, dynamic>.from(x['reservation'] as Map));
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = r;
    return Scaffold(
      appBar: AppBar(title: const Text('PICKUP PASS')),
      body: x == null
          ? Center(child: Text(error ?? 'Loading reservation…'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  x['status'] == 'borrowed'
                      ? Icons.check_circle
                      : Icons.lock_clock_outlined,
                  color: x['status'] == 'borrowed' ? Colors.green : red,
                  size: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  x['tool_name'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  x['status'] == 'borrowed'
                      ? 'PICKUP VERIFIED · TIMER RUNNING'
                      : x['status'] == 'expired'
                          ? 'RESERVATION EXPIRED'
                          : 'SHOW PASS AT THE LOCKER',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: red,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${rm(x['hourly_rate'] as num)} per hour · collect by ${dateTime(x['pickup_expires_at'])}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                if (x['status'] == 'reserved')
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: QrImageView(
                        data: x['pickup_qr'].toString(),
                        size: 230,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  x['status'] == 'borrowed'
                      ? 'The Locker Site verified this pass and unlocked the assigned locker. Rental time is updating automatically.'
                      : x['status'] == 'expired'
                          ? 'The one-hour pickup period has ended. Create a new reservation if this tool is still available.'
                          : 'Scan the QR on the separate Locker Site kiosk, or enter the PIN there. This pass is linked to ${x['tool_name']}. The timer will start only after kiosk verification.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (x['status'] == 'reserved')
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PICKUP PIN',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          x['pin'].toString(),
                          style: const TextStyle(
                            color: red,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            fontSize: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (x['status'] == 'borrowed')
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      children: [
                        Text(
                          'TIME BORROWED · ${elapsed((x['elapsed_seconds'] as num).toInt())}',
                          style: const TextStyle(
                            color: red,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Accrued charge: ${rm(x['rental_fee'] as num)}',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.sync),
                  label: const Text('REFRESH LOCKER STATUS'),
                ),
              ],
            ),
    );
  }
}

class RentalsPage extends StatelessWidget {
  const RentalsPage({
    super.key,
    required this.rentals,
    required this.onRefresh,
    required this.onPay,
    required this.onOpenReservation,
  });
  final List<Map<String, dynamic>> rentals;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>, Map<String, Object?>) onPay;
  final Future<void> Function(Map<String, dynamic>) onOpenReservation;
  @override
  Widget build(BuildContext context) {
    final active = rentals
        .where(
          (r) =>
              ['borrowed', 'reserved', 'return_scanning'].contains(r['status']),
        )
        .toList();
    final returned = rentals.where((r) => r['status'] == 'returned').toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MY RENTALS',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          if (active.isEmpty)
            const _InfoCard(
              icon: Icons.inventory_2_outlined,
              title: 'No active rental',
              detail: 'Your reservations and checked-out tools appear here.',
            ),
          ...active.map(
            (r) => Card(
              color: Colors.white,
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpenReservation(r),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r['tool_name'].toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            r['status']
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: red,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${rm(r['hourly_rate'] as num)} per hour',
                        style: const TextStyle(color: muted),
                      ),
                      if (r['status'] == 'borrowed' ||
                          r['status'] == 'return_scanning') ...[
                        Text(
                          'Time borrowed: ${elapsed((r['elapsed_seconds'] as num).toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Current charge: ${rm(r['rental_fee'] as num)}',
                          style: const TextStyle(
                            color: red,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Return at the Locker Site using the barcode attached to this tool.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                      if (r['status'] == 'reserved')
                        Text(
                          'Pick up by ${dateTime(r['pickup_expires_at'])}. Show your QR or PIN at the kiosk.',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      if (r['status'] == 'borrowed')
                        Text('Item barcode: ${r['barcode']}',
                            style: const TextStyle(color: muted, fontSize: 11)),
                      const SizedBox(height: 6),
                      const Text('Tap to view rental details',
                          style: TextStyle(
                              color: red,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (returned.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                'PAYMENT DUE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ),
          ...returned.where((r) => r['paid'] != true).map(
                (r) => Card(
                  color: Colors.white,
                  elevation: 0,
                  child: ListTile(
                    title: Text(r['tool_name'].toString()),
                    subtitle: Text(
                      '${r['charge_hours']} hour(s) · ${rm(r['rental_fee'] as num)}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(rental: r, onPay: onPay),
                        ),
                      ),
                      style: FilledButton.styleFrom(backgroundColor: red),
                      child: const Text('PAY'),
                    ),
                  ),
                ),
              ),
          ...returned.where((r) => r['paid'] == true).map(
                (r) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${r['tool_name']} · Paid'),
                  subtitle: Text(
                    '${r['payment_method']} · ${rm(r['rental_fee'] as num)}',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.rental, required this.onPay});
  final Map<String, dynamic> rental;
  final Future<void> Function(Map<String, dynamic>, Map<String, Object?>) onPay;
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final form = GlobalKey<FormState>();
  final number = TextEditingController(text: '4242 4242 4242 4242'),
      expiry = TextEditingController(text: '12/30'),
      cvv = TextEditingController(text: '123'),
      holder = TextEditingController(text: 'DEMO RESIDENT');
  String method = 'Card';
  String? error;
  bool paying = false;
  @override
  void dispose() {
    number.dispose();
    expiry.dispose();
    cvv.dispose();
    holder.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (method == 'Card' && !(form.currentState?.validate() ?? false)) return;
    setState(() => paying = true);
    try {
      await widget.onPay(widget.rental, {
        'method': method,
        if (method == 'Card') 'card_number': number.text,
        if (method == 'Card') 'expiry': expiry.text,
        if (method == 'Card') 'cvv': cvv.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo payment approved. No real funds were charged.'),
          ),
        );
        Navigator.pop(context);
      }
    } on ApiFailure catch (e) {
      if (mounted)
        setState(() {
          error = e.message;
          paying = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('PAYMENT')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'PAY YOUR RENTAL',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Card(
              color: Colors.white,
              elevation: 0,
              child: ListTile(
                title: Text(widget.rental['tool_name'].toString()),
                subtitle: Text(
                  '${widget.rental['charge_hours']} hour(s) × ${rm(widget.rental['hourly_rate'] as num)}/hour',
                ),
                trailing: Text(
                  rm(widget.rental['rental_fee'] as num),
                  style: const TextStyle(
                    color: red,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SELECT PAYMENT METHOD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
            DropdownButtonFormField<String>(
              initialValue: method,
              items: const [
                DropdownMenuItem(
                    value: 'Card', child: Text('Credit / debit card')),
                DropdownMenuItem(
                  value: 'FPX online banking',
                  child: Text('FPX online banking'),
                ),
                DropdownMenuItem(
                  value: "Touch 'n Go eWallet",
                  child: Text("Touch 'n Go eWallet"),
                ),
              ],
              onChanged: (v) => setState(() => method = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (method == 'Card') ...[
              const SizedBox(height: 12),
              Form(
                key: form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: holder,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder name',
                      ),
                      validator: (v) => (v?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Enter cardholder name',
                    ),
                    TextFormField(
                      controller: number,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Card number'),
                      validator: (v) =>
                          (v ?? '').replaceAll(RegExp(r'\D'), '') ==
                                  '4242424242424242'
                              ? null
                              : 'Use the demo card number shown below',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiry,
                            decoration: const InputDecoration(
                              labelText: 'Expiry MM/YY',
                            ),
                            validator: (v) => (v?.contains('/') ?? false)
                                ? null
                                : 'Enter MM/YY',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: cvv,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'CVV'),
                            validator: (v) =>
                                (v?.length == 3) ? null : 'Enter 3 digits',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Text(
                'Test payment only: use 4242 4242 4242 4242, any future expiry and a 3-digit CVV. Never enter a real card. Card details are not saved.',
                style: TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'This payment method is simulated. No bank or wallet service is contacted.',
                  style: TextStyle(color: muted),
                ),
              ),
            if (error != null) Text(error!, style: const TextStyle(color: red)),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: paying ? null : submit,
                style: FilledButton.styleFrom(backgroundColor: red),
                icon: const Icon(Icons.lock_outline),
                label: Text(
                  paying
                      ? 'PROCESSING…'
                      : 'PAY ${rm(widget.rental['rental_fee'] as num)}',
                ),
              ),
            ),
          ],
        ),
      );
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'HELP & TERMS',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const SupportReportPage()),
            ),
            style: FilledButton.styleFrom(backgroundColor: red),
            icon: const Icon(Icons.support_agent),
            label: const Text('CONTACT SUPPORT / REPORT DAMAGE'),
          ),
          const _Faq(
            'When does rental time start?',
            'The timer starts automatically when the Locker Site verifies your PIN or QR and opens the assigned locker.',
          ),
          const _Faq(
            'How is price calculated?',
            'Each item has an hourly rate. Time is charged for actual use, rounded up to each started hour with a one-hour minimum. The Locker Site return sensor stops the timer.',
          ),
          const _Faq(
            'How soon must I collect a reservation?',
            'Pick up within one hour after reserving. The kiosk rejects expired reservations.',
          ),
          const _Faq(
            'How do I return a tool?',
            'At the Locker Site, scan or type the barcode attached to the original tool. The kiosk opens its assigned locker and its occupancy camera confirms the compartment is dark.',
          ),
          const _Faq(
            'What if I find damage?',
            'Do not use the item. Contact township support with the item name, barcode and a description.',
          ),
          const _Faq(
            'Are card payments real?',
            'No. Use the designated test card only. No bank is contacted and no real funds are taken.',
          ),
        ],
      );
}

class SupportReportPage extends StatefulWidget {
  const SupportReportPage({super.key});
  @override
  State<SupportReportPage> createState() => _SupportReportPageState();
}

class _SupportReportPageState extends State<SupportReportPage> {
  final comment = TextEditingController();
  final attachments = <XFile>[];
  String kind = 'Damage or safety issue';
  bool sending = false;
  String? error;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> addPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => attachments.add(file));
  }

  Future<void> addVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => attachments.add(file));
  }

  Future<void> sendReport() async {
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await VaultApi.instance.submitReport(
        kind: kind,
        comment: comment.text,
        attachments: attachments,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('CONTACT SUPPORT')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(
                labelText: 'Report type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Damage or safety issue',
                  child: Text('Damage or safety issue'),
                ),
                DropdownMenuItem(
                  value: 'Customer support',
                  child: Text('Customer support'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => kind = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: comment,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Describe what happened or what you found…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: addPhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add photo'),
                ),
                OutlinedButton.icon(
                  onPressed: addVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Add video'),
                ),
              ],
            ),
            if (attachments.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map((file) {
                  final isImage = file.mimeType?.startsWith('image/') ??
                      RegExp(r'\.(jpg|jpeg|png|gif|webp)$',
                              caseSensitive: false)
                          .hasMatch(file.name);
                  return Stack(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                            color: const Color(0xFFEDE9E5),
                            borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: isImage
                            ? FutureBuilder(
                                future: file.readAsBytes(),
                                builder: (context, snapshot) => snapshot.hasData
                                    ? Image.memory(snapshot.data!,
                                        fit: BoxFit.cover)
                                    : const Center(
                                        child: CircularProgressIndicator()),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.videocam, color: red),
                                    Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(file.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 10)))
                                  ]),
                      ),
                      Positioned(
                          right: 2,
                          top: 2,
                          child: IconButton.filledTonal(
                              onPressed: () =>
                                  setState(() => attachments.remove(file)),
                              icon: const Icon(Icons.close, size: 17),
                              visualDensity: VisualDensity.compact)),
                    ],
                  );
                }).toList(),
              ),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: red))),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed:
                    comment.text.trim().isEmpty || sending ? null : sendReport,
                style: FilledButton.styleFrom(backgroundColor: red),
                child: Text(sending ? 'SENDING…' : 'SEND REPORT'),
              ),
            ),
          ],
        ),
      );
}

class _Faq extends StatelessWidget {
  const _Faq(this.q, this.a);
  final String q, a;
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        elevation: 0,
        child: ExpansionTile(
          title: Text(
            q,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              a,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        elevation: 0,
        child: ListTile(
          leading: Icon(icon, color: red),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(detail, style: const TextStyle(color: muted)),
        ),
      );
}
