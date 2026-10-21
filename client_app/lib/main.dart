import 'dart:async';
import 'dart:math' as math;

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
String toolAssetPath(String id) => switch (id) {
      'furniture_kit' => 'assets/tools/furniture_moving_kit.jpg',
      'workbench' => 'assets/tools/folding_workbench.jpg',
      'drain_auger' => 'assets/tools/manual_drain_auger.jpg',
      'window_kit' => 'assets/tools/window_cleaning_kit.jpg',
      _ => 'assets/tools/$id.jpg',
    };
String dateTime(dynamic value) {
  if (value == null) return '—';
  final d = DateTime.parse(value.toString()).toLocal();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day}/${d.month} $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}

String elapsed(int s) =>
    '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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
  List<String> get safetyTips => safety
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((tip) => tip.trim())
      .where((tip) => tip.isNotEmpty)
      .toList();
}

const tools = <VaultTool>[
  VaultTool(
    'step_ladder',
    '4-step safety ladder',
    'Home repair',
    'A sturdy ladder for shelves, curtains and ceiling fixtures.',
    'Before climbing, open the ladder fully and lock both spreaders. Place it on firm, level ground, with all feet flat. Face the ladder while climbing and keep three points of contact (two hands and one foot, or two feet and one hand). Keep your belt buckle between the rails, move it instead of overreaching, and never stand on the top step. Ask another adult to steady it when possible. Fold and carry it only after climbing down.',
    Icons.stairs,
    2,
  ),
  VaultTool(
    'cordless_drill',
    'Cordless drill-driver kit',
    'Home repair',
    'A compact drill-driver with common household bits.',
    'Choose a bit that matches the screw or hole, then fit it firmly with the battery removed. Mark and clamp the workpiece; wear eye protection. Check for hidden wiring and pipes, and do not drill near sockets or plumbing. Hold the drill straight, start slowly, and let the bit stop before lifting it away. Remove the battery before changing bits or clearing a jam.',
    Icons.handyman,
    3,
  ),
  VaultTool(
    'wet_dry_vacuum',
    'Wet & dry vacuum',
    'Cleaning',
    'A compact vacuum for small spills, dust and cleanup.',
    'Fit the correct filter and set the machine to dry or wet mode before switching it on. Keep the nozzle clear and guide it slowly over the spill or debris. Never vacuum hot ash, flammable liquids, or hazardous dust. Switch off and unplug before emptying the tank; allow wet parts to dry before storage.',
    Icons.cleaning_services,
    4,
  ),
  VaultTool(
    'carpet_cleaner',
    'Carpet & upholstery cleaner',
    'Cleaning',
    'A portable extractor for rugs, sofas and car seats.',
    'Vacuum loose dirt first and test the cleaning solution on a hidden patch. Fill the tank only to its marked line with the recommended solution. Work in small overlapping passes without soaking the fabric, then make a water-only rinse pass if the label recommends it. Empty and rinse the tanks after use; keep the machine unplugged while cleaning it.',
    Icons.weekend,
    5,
  ),
  VaultTool(
    'pressure_washer',
    'Adjustable pressure washer',
    'Garden',
    'A consumer pressure washer for patios and outdoor furniture.',
    'Connect the hose and water supply before powering the washer. Wear closed shoes and eye protection; start with the widest spray and lowest pressure on an inconspicuous area. Hold the lance with both hands and keep a safe distance. Never point it at people, pets, electrical equipment, or fragile surfaces. Turn it off and release pressure before changing nozzles.',
    Icons.water,
    5,
  ),
  VaultTool(
    'steam_cleaner',
    'Household steam cleaner',
    'Cleaning',
    'A small steam cleaner for sealed floors and grout.',
    'Fill to the marked line with the unit unplugged, then attach the correct floor or grout accessory. Let it heat fully and move the nozzle steadily over sealed surfaces. Steam can burn: keep hands, skin, children, and pets away from the nozzle and vapour. Switch off, unplug, and let the unit cool completely before opening or refilling.',
    Icons.air,
    4,
  ),
  VaultTool(
    'hand_truck',
    'Folding hand truck',
    'Moving',
    'A compact trolley for boxes and small appliances.',
    'Tilt the hand truck back and slide its toe plate under the load. Keep the load within its printed weight limit, centre it over the wheels, and secure it with the strap. Push rather than pull where possible; move slowly and ask for help on steps or uneven ground. Keep hands and feet clear when lowering the load.',
    Icons.local_shipping_outlined,
    2,
  ),
  VaultTool(
    'furniture_kit',
    'Furniture moving kit',
    'Moving',
    'Lifter and floor-safe sliders for rearranging furniture.',
    'Check that the floor and furniture feet are suitable for the sliders. Use the lifter to raise one corner slightly, place a slider underneath, and repeat one corner at a time. Keep fingers out from under the furniture and move heavy items with another person. Push gently and stop if the item catches or becomes unstable.',
    Icons.chair_alt_outlined,
    2,
  ),
  VaultTool(
    'laser_measure',
    'Laser distance measurer',
    'Home repair',
    'A handheld digital measurer for rooms and furniture.',
    'Press the power button and select the required measurement mode. Place the back of the device against the starting surface, aim the laser dot at the target, and press measure; read the result on the display. Do not look into the laser aperture or point it at anyone. Keep the device steady and switch it off after use.',
    Icons.straighten,
    2,
  ),
  VaultTool(
    'laser_level',
    'Self-leveling laser level',
    'Home repair',
    'A line laser for aligning shelves and picture frames.',
    'Set the level on a stable surface or secure it to the supplied mount. Switch it on and wait for the line to stop blinking before marking the wall. Do not stare into the beam or aim it at anyone’s eyes. Keep it away from children, switch it off before moving it, and store it in its case.',
    Icons.square_foot,
    3,
  ),
  VaultTool(
    'stud_finder',
    'Wall stud & wire detector',
    'Home repair',
    'A wall scanner to locate studs and flag possible wiring.',
    'Read the device label, select the correct wall mode, and calibrate it on a clear section as instructed. Move it slowly across the wall and mark likely studs or warning signals from both directions. A detector cannot guarantee a wall is safe to drill; avoid outlets, switches, and plumbing, and consult a qualified person if unsure.',
    Icons.sensors,
    2,
  ),
  VaultTool(
    'workbench',
    'Folding workbench',
    'Home repair',
    'A portable clamping bench for light DIY and assembly.',
    'Unfold the bench fully and lock each leg before use. Place it on a level floor, stay within the printed load limit, and use the clamps to secure the workpiece. Keep hands clear of moving clamps. Do not stand, sit, or climb on the bench; fold it only after removing tools and workpieces.',
    Icons.table_restaurant,
    2,
  ),
  VaultTool(
    'drain_auger',
    'Manual drain auger',
    'Home repair',
    'A hand-cranked drain snake for simple household blockages.',
    'Wear gloves and eye protection. Feed the cable gently into the drain while turning the handle; do not force it around bends. Pull the cable back slowly and clean it after use. Never use it with chemical drain cleaners, and stop if the pipe resists or appears damaged.',
    Icons.plumbing,
    2,
  ),
  VaultTool(
    'dehumidifier',
    'Portable dehumidifier',
    'Home care',
    'A room-size unit for damp areas and laundry drying.',
    'Keep the unit upright with space around its air vents and place it on a dry, level floor. Use a grounded outlet and keep it away from splashes. Set the humidity level, empty the water tank when full, and unplug before cleaning. Do not tilt the unit while water remains inside.',
    Icons.device_thermostat,
    3,
  ),
  VaultTool(
    'window_kit',
    'Ground-reach window cleaning kit',
    'Cleaning',
    'A telescopic pole and squeegee for ground-reachable windows.',
    'Fit the squeegee or cloth securely to the telescopic pole and extend it only as far as you can control from the ground. Use steady strokes on ground-reachable windows. Do not lean out of a window or climb a ladder, balcony rail, or chair; stop if the glass is cracked or the area is unsafe.',
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
            builder: (_) => PickupPassPage(
              id: r['id'].toString(),
            ),
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
                    Image.asset('assets/tool_vault_logo.png',
                        width: 72, height: 72),
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
        ? CatalogPage(
            inventory: inventory,
            onRent: onRent,
            onHelp: () => onTab(2),
          )
        : tab == 1
            ? RentalsPage(
                rentals: rentals,
                onRefresh: onRefresh,
                onPay: onPay,
                onOpenReservation: onOpenReservation)
            : const HelpPage();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/tool_vault_logo.png', width: 30, height: 30),
            const SizedBox(width: 8),
            const Text('TOOL VAULT',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6)),
          ],
        ),
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
  const CatalogPage({
    super.key,
    required this.inventory,
    required this.onRent,
    required this.onHelp,
  });
  final List<Map<String, dynamic>> inventory;
  final Future<void> Function(VaultTool) onRent;
  final VoidCallback onHelp;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _ToolChatMessage {
  const _ToolChatMessage({
    required this.fromResident,
    required this.text,
    this.tools = const [],
    this.openHelp = false,
  });

  final bool fromResident;
  final String text;
  final List<VaultTool> tools;
  final bool openHelp;
}

class _CatalogPageState extends State<CatalogPage> {
  final search = TextEditingController();
  final situation = TextEditingController();
  final chatScroll = ScrollController();
  String category = 'All';
  bool assistantOpen = false;
  bool assistantOnRight = true;
  Offset? assistantPosition;
  final chatMessages = <_ToolChatMessage>[
    const _ToolChatMessage(
      fromResident: false,
      text: 'Hi! I’m the Tool Vault assistant. Tell me what you’re trying to do at home, and I’ll suggest a tool to help.',
    ),
  ];
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
    situation.dispose();
    chatScroll.dispose();
    super.dispose();
  }

  Future<void> openTool(VaultTool tool) async {
    final item = widget.inventory.firstWhere(
      (row) => row['id']?.toString() == tool.id,
      orElse: () => <String, dynamic>{},
    );
    final available = (item['available'] as num?)?.toInt() ?? 0;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookingPage(
          tool: tool,
          available: available,
          onReserve: () => widget.onRent(tool),
        ),
      ),
    );
  }

  void sendChatMessage() {
    final query = situation.text.trim().toLowerCase();
    if (query.isEmpty) return;
    const intentWords = <String, List<String>>{
      'step_ladder': [
        'high', 'ceiling', 'curtain', 'ladder', 'reach', 'shelf',
        'light bulb', 'change a bulb', 'top cupboard', 'paint a wall',
      ],
      'cordless_drill': [
        'drill',
        'screw',
        'assemble',
        'hole',
        'furniture',
        'hang',
        'mount',
        'install shelf',
        'put up a picture',
        'flat pack',
      ],
      'wet_dry_vacuum': [
        'spill', 'water', 'dust', 'debris', 'vacuum', 'mess', 'wet floor',
        'flood', 'sawdust', 'liquid', 'clean up a spill', 'water leak',
      ],
      'carpet_cleaner': [
        'carpet', 'sofa', 'upholstery', 'stain', 'rug', 'couch',
        'fabric chair', 'pet stain', 'clean the sofa', 'wash carpet',
      ],
      'pressure_washer': [
        'patio',
        'driveway',
        'outdoor',
        'deck',
        'wash outside',
        'clean the patio',
        'wash the driveway',
      ],
      'steam_cleaner': [
        'steam', 'grout', 'sealed floor', 'tile', 'tile floor', 'hard floor',
        'bathroom tiles', 'kitchen floor', 'clean tiles', 'mop the floor',
      ],
      'hand_truck': [
        'move boxes', 'heavy box', 'appliance', 'transport', 'moving house',
        '搬家', '搬运', 'move house', 'carry boxes', '搬东西',
      ],
      'furniture_kit': [
        'move furniture', 'heavy furniture', 'rearrange', 'move a cabinet',
        'move a sofa', 'move a table', 'shift furniture',
      ],
      'laser_measure': [
        'measure room', 'distance', 'room size', 'dimensions', 'measure wall',
        'measure a space',
      ],
      'laser_level': [
        'straight line', 'align', 'level shelf', 'hang picture', 'straight shelf',
      ],
      'stud_finder': [
        'wire', 'stud', 'drill wall', 'wall', 'find a stud', 'wall framing',
      ],
      'workbench': [
        'work surface', 'clamp', 'cut wood', 'workbench', 'small repair',
      ],
      'drain_auger': [
        'blocked drain', 'clog', 'sink', 'drain', 'blocked sink', 'slow drain',
      ],
      'dehumidifier': [
        'damp', 'humidity', 'moisture', 'dry clothes', 'musty', 'condensation',
      ],
      'window_kit': [
        'window', 'glass cleaning', 'clean windows', 'streaky glass',
        'clean the glass',
      ],
    };
    final ids = <String>{};
    for (final entry in intentWords.entries) {
      if (entry.value.any(query.contains)) ids.add(entry.key);
    }
    final reportsDamage = [
      'damage', 'damaged', 'broken', 'cracked', 'faulty', 'malfunction',
      'sparking', 'smoke', 'unsafe', 'not working', 'stopped working',
      'overheating', 'does not work', 'isn’t working', "isn't working",
      'not safe', 'got damaged', 'tool is damaged', 'tool broke',
    ].any(query.contains);
    final asksAboutFloor = ['floor', 'tile', 'grout', 'mop'].any(query.contains);
    final mentionsCarpet = ['carpet', 'rug', 'mat'].any(query.contains);
    if (asksAboutFloor && !mentionsCarpet &&
        !ids.contains('steam_cleaner') &&
        !['wood', 'laminate', 'unsealed'].any(query.contains)) {
      ids.add('steam_cleaner');
      ids.add('carpet_cleaner');
    }
    final matches = reportsDamage
        ? <VaultTool>[]
        : tools.where((tool) => ids.contains(tool.id)).take(4).toList();
    final isGreeting = RegExp(
      r'^(hi|hello|hey)\b.*|^(good morning|good afternoon|good evening)\b.*$',
    ).hasMatch(query);
    final asksWhatCanYouDo = [
      'what can you do',
      'how can you help',
      'what do you do',
    ].any(query.contains);
    final saysThanks = ['thank you', 'thanks'].any(query.contains);

    String answer;
    if (reportsDamage) {
      answer = 'Stop using the tool and keep it somewhere safe. Don’t try to repair it yourself. Open Help & Support to report the damage or safety issue, and attach a photo or video if you can.';
    } else if (isGreeting || asksWhatCanYouDo) {
      answer = 'Hi! I can help match a home task to a Tool Vault item. Try asking “I want to clean the floor,” “the tool is damaged,” “hang a shelf,” or “move heavy boxes.”';
    } else if (saysThanks) {
      answer = 'You’re welcome! Ask me about another home task whenever you need a tool suggestion.';
    } else if (asksAboutFloor &&
        ['wood', 'laminate', 'unsealed'].any(query.contains)) {
      answer = 'For wood or laminate floors, check the flooring instructions before choosing a cleaning tool. Steam can damage some finishes. Tell me whether it is sealed tile, carpet, or another surface and I can narrow it down.';
    } else if (asksAboutFloor) {
      answer = 'The right choice depends on the surface. The carpet cleaner is for rugs and carpet; the steam cleaner is for suitable sealed hard floors. Avoid steam on unsealed wood or laminate.';
    } else if (matches.isEmpty) {
      answer = 'I couldn’t match that task yet. Try “clean tile floor,” “wash the sofa,” “hang a shelf,” “unblock a sink,” “move heavy boxes,” or describe what you need to do.';
    } else {
      answer = 'These tools may help. Tap an item to open its page, check availability, and read its safety guide.';
    }
    setState(() {
      chatMessages.add(_ToolChatMessage(fromResident: true, text: situation.text.trim()));
      chatMessages.add(_ToolChatMessage(
        fromResident: false,
        text: answer,
        tools: (isGreeting || asksWhatCanYouDo || saysThanks || reportsDamage)
            ? const []
            : matches,
        openHelp: reportsDamage,
      ));
      situation.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScroll.hasClients) {
        chatScroll.animateTo(
          chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
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
    return LayoutBuilder(
      builder: (context, bounds) {
        final panelWidth = assistantOpen
            ? math.max(1.0, math.min(520.0, bounds.maxWidth - 16)).toDouble()
            : 58.0;
        final panelHeight = assistantOpen
            ? math.max(1.0, math.min(520.0, bounds.maxHeight - 16)).toDouble()
            : 58.0;
        final maxLeft = math.max(8.0, bounds.maxWidth - panelWidth - 8).toDouble();
        final maxTop = math.max(8.0, bounds.maxHeight - panelHeight - 8).toDouble();
        final initialPosition = Offset(
          math.max(8.0, bounds.maxWidth - panelWidth - 8).toDouble(),
          math.max(8.0, bounds.maxHeight - panelHeight - 16).toDouble(),
        );
        final position = assistantPosition ?? initialPosition;
        final left = position.dx.clamp(8.0, maxLeft).toDouble();
        final top = position.dy.clamp(8.0, maxTop).toDouble();

        void moveAssistant(Offset delta) {
          final current = assistantPosition ?? Offset(left, top);
          setState(() {
            assistantPosition = Offset(
              (current.dx + delta.dx).clamp(8.0, maxLeft).toDouble(),
              (current.dy + delta.dy).clamp(8.0, maxTop).toDouble(),
            );
          });
        }

        void snapAssistantToEdge() {
          final current = assistantPosition ?? Offset(left, top);
          final onRight = current.dx + panelWidth / 2 >= bounds.maxWidth / 2;
          setState(() {
            assistantOnRight = onRight;
            assistantPosition = Offset(
              onRight ? maxLeft : 8,
              current.dy.clamp(8.0, maxTop).toDouble(),
            );
          });
        }

        void toggleAssistant(bool open) {
          final nextWidth = open
              ? math.max(1.0, math.min(520.0, bounds.maxWidth - 16)).toDouble()
              : 58.0;
          final nextHeight = open
              ? math.max(1.0, math.min(520.0, bounds.maxHeight - 16)).toDouble()
              : 58.0;
          final nextLeft = assistantOnRight
              ? math.max(8.0, bounds.maxWidth - nextWidth - 8).toDouble()
              : 8.0;
          final nextTop = (assistantPosition?.dy ?? top)
              .clamp(8.0, math.max(8.0, bounds.maxHeight - nextHeight - 8))
              .toDouble();
          setState(() {
            assistantOpen = open;
            assistantPosition = Offset(nextLeft, nextTop);
          });
        }

        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
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
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 18) / 3;
            final cardHeight = (cardWidth * 1.8).clamp(250.0, 400.0);
            return GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: cardWidth / cardHeight,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: list
                  .map((t) => ToolCard(
                        tool: t,
                        available: stock[t.id] ?? 0,
                        onRent: () => openTool(t),
                      ))
                  .toList(),
            );
          },
        ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: left,
              top: top,
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: panelWidth,
                  height: panelHeight,
                  child: assistantOpen
                      ? Column(
                          children: [
                            GestureDetector(
                              onPanUpdate: (details) => moveAssistant(details.delta),
                              onPanEnd: (_) => snapAssistantToEdge(),
                              child: Container(
                                color: red,
                                padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.drag_indicator,
                                        color: Colors.white70, size: 20),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.support_agent,
                                        color: Colors.white, size: 21),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'TOOL VAULT ASSISTANT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => toggleAssistant(false),
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: chatScroll,
                                padding: const EdgeInsets.all(10),
                                itemCount: chatMessages.length,
                                itemBuilder: (context, index) {
                                  final message = chatMessages[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: message.fromResident
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                              maxWidth: panelWidth * .82),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: message.fromResident
                                                ? const Color(0xFFF4E8EA)
                                                : const Color(0xFFF6F5F2),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Text(message.text,
                                              style: const TextStyle(
                                                  color: ink,
                                                  fontSize: 12,
                                                  height: 1.35)),
                                        ),
                                        ...message.tools.map((tool) => Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6),
                                              child: SizedBox(
                                                width: panelWidth * .9,
                                                child: Material(
                                                  color: const Color(0xFFFFF5E7),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    onTap: () {
                                                      toggleAssistant(false);
                                                      openTool(tool);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(9),
                                                      child: Row(
                                                        children: [
                                                          Icon(tool.icon,
                                                              color: red,
                                                              size: 20),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(tool.name,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w800)),
                                                                Text(
                                                                    '${rm(tool.rate)} per hour · Open details',
                                                                    style: const TextStyle(
                                                                        color:
                                                                            muted,
                                                                        fontSize:
                                                                            10)),
                                                              ],
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons.chevron_right,
                                                              color: red),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )),
                                        if (message.openHelp)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                toggleAssistant(false);
                                                widget.onHelp();
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                              ),
                                              icon: const Icon(
                                                  Icons.support_agent,
                                                  size: 17),
                                              label: const Text(
                                                  'OPEN HELP & SUPPORT'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: situation,
                                      onSubmitted: (_) => sendChatMessage(),
                                      decoration: InputDecoration(
                                        hintText: 'Ask about a home task…',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 11),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filled(
                                    onPressed: sendChatMessage,
                                    style: IconButton.styleFrom(
                                        backgroundColor: red),
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onPanUpdate: (details) => moveAssistant(details.delta),
                          onPanEnd: (_) => snapAssistantToEdge(),
                          child: InkWell(
                            onTap: () => toggleAssistant(true),
                            child: const Center(
                              child: Icon(Icons.chat_bubble,
                                  color: red, size: 27),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ToolCard extends StatefulWidget {
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
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hovering ? .12 : .05),
              blurRadius: hovering ? 14 : 5,
              offset: Offset(0, hovering ? 6 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: const Color(0xFFFFF5E7),
                    alignment: Alignment.center,
                    child: Image.asset(
                      toolAssetPath(tool.id),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(tool.icon, color: red, size: 44),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(tool.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 11, height: 1.15)),
              const SizedBox(height: 3),
              Text(tool.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: muted, fontSize: 9, height: 1.2)),
              const Spacer(),
              Text('${rm(tool.rate)} / hour',
                  style: const TextStyle(
                      color: red, fontWeight: FontWeight.w900, fontSize: 10)),
              Text(
                  widget.available > 0
                      ? '${widget.available} available'
                      : 'Unavailable',
                  maxLines: 1,
                  style: TextStyle(
                      color: widget.available > 0 ? muted : red, fontSize: 9)),
              const SizedBox(height: 5),
              SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: widget.onRent,
                  style: FilledButton.styleFrom(
                    backgroundColor: red,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    textStyle: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('VIEW DETAILS', maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.tool,
    required this.available,
    required this.onReserve,
  });
  final VaultTool tool;
  final int available;
  final Future<void> Function() onReserve;
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool accepted = false, loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TOOL DETAILS')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  color: const Color(0xFFFFF5E7),
                  alignment: Alignment.center,
                  child: Image.asset(
                    toolAssetPath(widget.tool.id),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(widget.tool.icon, color: red, size: 72),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 17),
                  label: Text(widget.tool.category),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(
                    widget.available > 0
                        ? Icons.check_circle_outline
                        : Icons.do_not_disturb_on_outlined,
                    size: 17,
                    color: widget.available > 0 ? Colors.green : red,
                  ),
                  label: Text(widget.available > 0
                      ? '${widget.available} available'
                      : 'Currently unavailable'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.tool.name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tool.description,
              style: const TextStyle(color: muted, fontSize: 15, height: 1.5),
            ),
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 4),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${rm(widget.tool.rate)} per hour',
                            style: const TextStyle(
                                color: red,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 3),
                        const Text(
                          'Charged for actual rental time, rounded up to each started hour.',
                          style: TextStyle(color: muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1E4BD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: red),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text('HOW TO USE IT SAFELY',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...widget.tool.safetyTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: red, fontWeight: FontWeight.w900)),
                          Expanded(
                            child:
                                Text(tip, style: const TextStyle(height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Pick up within 15 minutes. The rental timer starts only when the Locker Site verifies your PIN or QR. The hourly charge is calculated when its return sensor confirms the item is back.',
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
                onPressed: accepted && !loading && widget.available > 0
                    ? () async {
                        setState(() => loading = true);
                        await widget.onReserve();
                        if (mounted) setState(() => loading = false);
                      }
                    : null,
                style: FilledButton.styleFrom(backgroundColor: red),
                child: Text(
                  loading
                      ? 'RESERVING…'
                      : widget.available > 0
                          ? 'RESERVE & GENERATE PICKUP PASS'
                          : 'CURRENTLY UNAVAILABLE',
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
  bool issuingReturnPass = false;
  bool returnPassShown = false;
  bool didPopForReturnExpiry = false;
  bool returnSuccessShown = false;
  DateTime? returnPassExpiresAt;
  Timer? poll;
  Timer? returnSuccessTimer;
  @override
  void initState() {
    super.initState();
    refresh();
    poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  @override
  void dispose() {
    poll?.cancel();
    returnSuccessTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final x = await VaultApi.instance.request(
        'GET',
        '/api/reservations/${widget.id}',
      );
      final data = Map<String, dynamic>.from(x['reservation'] as Map);
      if (['return_requested', 'return_scanning'].contains(data['status']) &&
          data['return_qr'] != null) {
        returnPassShown = true;
        returnPassExpiresAt = DateTime.tryParse(
          data['return_expires_at']?.toString() ?? '',
        );
      }
      if (returnPassShown && data['status'] == 'borrowed') {
        final expiry = returnPassExpiresAt ?? DateTime.tryParse(
          r?['return_expires_at']?.toString() ?? '',
        );
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          // A slower, earlier refresh can finish after pass creation and return
          // stale Borrowed data. Keep the newly issued pass visible until expiry.
          final current = r;
          data['status'] = current?['status'] ?? 'return_requested';
          data['return_pin'] = current?['return_pin'];
          data['return_qr'] = current?['return_qr'];
          data['return_expires_at'] = expiry.toIso8601String();
        } else if (expiry != null && mounted && !didPopForReturnExpiry) {
          returnPassShown = false;
          returnPassExpiresAt = null;
          didPopForReturnExpiry = true;
          Navigator.of(context).pop();
          return;
        }
      }
      if (mounted) {
        setState(() => r = data);
        if (data['status'] == 'returned' && !returnSuccessShown) {
          returnSuccessShown = true;
          poll?.cancel();
          returnSuccessTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> generateReturnPass() async {
    if (issuingReturnPass) return;
    setState(() {
      issuingReturnPass = true;
      error = null;
    });
    try {
      final result = await VaultApi.instance.request(
        'POST',
        '/api/locker/return-pass',
        body: {'reservation_id': widget.id},
      );
      if (mounted) {
        final updated = Map<String, dynamic>.from(result['reservation'] as Map);
        returnPassExpiresAt = DateTime.tryParse(
          updated['return_expires_at']?.toString() ?? '',
        );
        returnPassShown = true;
        setState(() => r = updated);
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => issuingReturnPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = r;
    final returnedSuccessfully = returnSuccessShown && x?['status'] == 'returned';
    return Scaffold(
      appBar: AppBar(
        title: Text(returnedSuccessfully
            ? 'RETURN COMPLETE'
            : x?['status'] == 'reserved'
                ? 'PICKUP PASS'
                : 'RENTAL STATUS'),
      ),
      body: returnedSuccessfully
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F4E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Color(0xFF39834A), size: 50),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'RETURNED SUCCESSFULLY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${x?['tool_name'] ?? 'Your tool'} has been returned and the rental timer has stopped.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Final rental charge: ${rm((x?['rental_fee'] as num?) ?? 0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: red, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Returning to My Rentals in 10 seconds…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : x == null
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
                const SizedBox(height: 8),
                Text(
                  x['status'] == 'borrowed'
                      ? 'BORROWED SUCCESSFULLY · TIMER RUNNING'
                      : x['status'] == 'return_requested'
                          ? 'RETURN PASS READY · TIMER RUNNING'
                          : x['status'] == 'return_scanning'
                              ? 'RETURN IN PROGRESS · TIMER RUNNING'
                              : x['status'] == 'expired'
                                  ? 'RESERVATION EXPIRED'
                                  : 'SHOW PASS AT THE LOCKER',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: red,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${rm(x['hourly_rate'] as num)} per hour${x['status'] == 'reserved' ? ' · collect within 15 minutes, by ${dateTime(x['pickup_expires_at'])}' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                if (x['status'] == 'reserved' ||
                    (['return_requested', 'return_scanning']
                            .contains(x['status']) &&
                        x['return_qr'] != null)) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: QrImageView(
                        data: (x['return_qr'] ?? x['pickup_qr']).toString(),
                        size: 230,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  ['return_requested', 'return_scanning']
                          .contains(x['status'])
                      ? 'Show this new return QR or PIN at the kiosk within two minutes. Rental time keeps running while you wait.'
                      : x['status'] == 'borrowed'
                          ? 'You borrowed this tool successfully. To return it, open this rental from My Rentals to generate a fresh return pass.'
                      : x['status'] == 'expired'
                          ? 'The 15-minute pickup period has ended. Create a new reservation if this tool is still available.'
                          : 'Scan the QR on the separate Locker Site kiosk, or enter the PIN there. This pass is linked to ${x['tool_name']}. The timer will start only after kiosk verification.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (x['status'] == 'reserved' ||
                    (['return_requested', 'return_scanning']
                        .contains(x['status']) &&
                        x['return_pin'] != null))
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          x['status'] == 'reserved'
                              ? 'PICKUP PIN'
                              : 'RETURN PIN',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          (x['return_pin'] ?? x['pin']).toString(),
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
                if (['borrowed', 'return_requested', 'return_scanning']
                    .contains(x['status']))
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
                if (x['status'] == 'borrowed')
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: FilledButton.icon(
                      onPressed:
                          issuingReturnPass ? null : generateReturnPass,
                      style: FilledButton.styleFrom(
                        backgroundColor: red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        minimumSize: const Size.fromHeight(54),
                      ),
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(issuingReturnPass
                          ? 'GENERATING RETURN PASS…'
                          : 'GENERATE RETURN PASS'),
                    ),
                  ),
                if (x['status'] == 'reserved')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel reservation?'),
                            content: const Text(
                                'This will release the tool for other residents.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('KEEP RESERVATION'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(backgroundColor: red),
                                child: const Text('CANCEL RESERVATION'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !mounted) return;
                        try {
                          await VaultApi.instance.request(
                            'POST',
                            '/api/reservations/cancel',
                            body: {'reservation_id': widget.id},
                          );
                          if (mounted) Navigator.of(context).pop();
                        } on ApiFailure catch (e) {
                          if (mounted) setState(() => error = e.message);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: red,
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('CANCEL RESERVATION'),
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: red)),
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
              ['borrowed', 'reserved', 'return_requested', 'return_scanning']
                  .contains(r['status']),
        )
        .toList();
    final returned = rentals.where((r) => r['status'] == 'returned').toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MY RENTALS',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => PaymentHistoryPage(
                      payments: returned.where((r) => r['paid'] == true).toList(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('HISTORY'),
                style: TextButton.styleFrom(foregroundColor: red),
              ),
            ],
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
                          ['return_requested', 'return_scanning']
                                  .contains(r['status'])
                                ? 'RETURNING'
                                : r['status']
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
                      if (['borrowed', 'return_requested', 'return_scanning']
                          .contains(r['status'])) ...[
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
                        Text(
                          ['return_requested', 'return_scanning']
                                  .contains(r['status'])
                              ? 'Return pass ready. Use it at the kiosk within two minutes.'
                              : 'Open this rental to generate a fresh two-minute return QR and PIN.',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                      if (r['status'] == 'reserved')
                        Text(
                          'Collect within 15 minutes, by ${dateTime(r['pickup_expires_at'])}. Show your QR or PIN at the kiosk.',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
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
        ],
      ),
    );
  }
}

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key, required this.payments});
  final List<Map<String, dynamic>> payments;

  @override
  Widget build(BuildContext context) {
    final history = [...payments]
      ..sort((a, b) => (b['paid_at'] ?? '').toString().compareTo(
            (a['paid_at'] ?? '').toString(),
          ));
    return Scaffold(
      appBar: AppBar(title: const Text('PAYMENT HISTORY')),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: _InfoCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'No payment history yet',
                  detail: 'Completed rental payments will appear here.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'PAID RENTALS',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...history.map(
                  (r) => Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF39834A), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r['tool_name'].toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                rm(r['rental_fee'] as num),
                                style: const TextStyle(
                                  color: red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${r['charge_hours']} hour(s) · ${r['payment_method'] ?? 'Payment'}',
                            style: const TextStyle(color: muted),
                          ),
                          if (r['last4'] != null)
                            Text('Card ending in ${r['last4']}',
                                style: const TextStyle(color: muted)),
                          Text('Paid ${dateTime(r['paid_at'])}',
                              style: const TextStyle(color: muted)),
                        ],
                      ),
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
            content: Text('Payment approved successfully.'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
            'Collect your reserved tool within 15 minutes. After that, the reservation expires and the tool becomes available to other residents.',
          ),
          const _Faq(
            'How do I return a tool?',
            'Open the borrowed rental from My Rentals, then tap Generate Return Pass. Use the new QR or PIN at the kiosk within two minutes; it opens the locker assigned to that tool. If the pass expires while you are viewing it, you will return to My Rentals and can open the rental to generate another pass.',
          ),
          const _Faq(
            'Does the rental timer stop while I prepare to return it?',
            'No. The rental timer keeps running until the kiosk confirms the tool has been returned. The two-minute return pass window does not pause the timer. If it expires, the rental returns to Borrowed and you can generate a new pass.',
          ),
          const _Faq(
            'What if I find damage?',
            'Do not use the item. Contact township support with the tool name and a description of the damage.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const SupportReportPage()),
            ),
            style: FilledButton.styleFrom(backgroundColor: red),
            icon: const Icon(Icons.support_agent),
            label: const Text('CONTACT SUPPORT / REPORT DAMAGE'),
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
  bool submitted = false;
  String? error;
  Timer? successTimer;
  @override
  void dispose() {
    successTimer?.cancel();
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
      if (mounted) {
        setState(() => submitted = true);
        successTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void goBack() {
    successTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(submitted ? 'REPORT SUBMITTED' : 'CONTACT SUPPORT')),
        body: submitted
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F4E8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF39834A), size: 46),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'REPORT SUBMITTED SUCCESSFULLY',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Thank you. The township support team will review your report. This page will close automatically in 10 seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: goBack,
                          style: FilledButton.styleFrom(backgroundColor: red),
                          child: const Text('BACK'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
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
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  a,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: muted, fontSize: 12, height: 1.45),
                ),
              ),
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
