// Renders the frames of doc/demo.gif and doc/style.gif.
// Run: flutter test tool/render_demo_test.dart
// then: python tool/make_gif.py   (needs Pillow).
// Uses Roboto and the Material icons from the Flutter SDK (path from FLUTTER_ROOT).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

const _frameMs = 50; // 20 fps

/// A small, made-up notes app. The tour walks through it.
class _NotesApp extends StatefulWidget {
  const _NotesApp({required this.style, required this.dark});

  final ArrowRingStyle style;
  final bool dark;

  @override
  State<_NotesApp> createState() => _NotesAppState();
}

late TourController _tour;

class _NotesAppState extends State<_NotesApp> {
  final _fab = GlobalKey();
  final _search = GlobalKey();
  final _settings = GlobalKey();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tour = TourController(
      tapGuard: Duration.zero,
      steps: [
        TourStep(
          id: 'new',
          title: 'Write something down',
          text: 'Tap the plus to start a new note.',
          target: _fab,
          arrowLabel: 'New note',
        ),
        TourStep(
          id: 'search',
          title: 'Find it again',
          text: 'Search looks through every note you have.',
          target: _search,
          arrowLabel: 'Search',
        ),
        TourStep(
          id: 'settings',
          title: 'Make it yours',
          text: 'Pick a theme and decide how notes are sorted.',
          target: _settings,
          arrowLabel: 'Settings',
        ),
        const TourStep(
          id: 'done',
          title: 'You are all set',
          text: 'The tour only showed you around, nothing was changed.',
        ),
      ],
      onStepChanged: (index, step) {
        setState(() => _tab = const [0, 1, 2, 0][index]);
      },
    );
  }

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  static const _notes = [
    ('Groceries', 'Oat milk, coffee, lemons'),
    ('Book ideas', 'A lighthouse that moves'),
    ('Workout', 'Monday: legs. Thursday: back'),
    ('Trip to Lisbon', 'Tram 28, pastel de nata'),
    ('Birthday gift', 'Something handmade'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Notes')),
          body: switch (_tab) {
            1 => const Center(child: Text('Search your notes')),
            2 => ListView(
              children: const [
                SwitchListTile(value: true, onChanged: null, title: Text('Dark theme')),
                SwitchListTile(value: false, onChanged: null, title: Text('Sort by date')),
              ],
            ),
            _ => ListView(
              children: [
                for (final (title, body) in _notes)
                  ListTile(title: Text(title), subtitle: Text(body)),
              ],
            ),
          },
          floatingActionButton: _tab == 0
              ? FloatingActionButton(key: _fab, onPressed: () {}, child: const Icon(Icons.add))
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.notes), label: 'Notes'),
              NavigationDestination(icon: Icon(Icons.search, key: _search), label: 'Search'),
              NavigationDestination(icon: Icon(Icons.settings, key: _settings), label: 'Settings'),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _tour,
          builder: (context, _) {
            final step = _tour.current;
            final i = _tour.index;
            if (step == null || i == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: TourOverlay(
                target: step.target,
                arrowLabel: step.arrowLabel,
                arrowStyle: widget.style,
                cardAlignment: Alignment.topCenter,
                card: TourCard(
                  title: step.title,
                  text: step.text,
                  progress: '${i + 1} of ${_tour.steps.length}',
                  backLabel: 'Back',
                  nextLabel: i == _tour.steps.length - 1 ? 'Done' : 'Next',
                  skipLabel: 'Skip',
                  onBack: i == 0 ? null : _tour.back,
                  onNext: _tour.next,
                  onSkip: _tour.skip,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? r'E:\flutter-sdk\flutter';
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  ByteData read(String name) => ByteData.sublistView(File('$fonts/$name').readAsBytesSync());
  final roboto = FontLoader('Roboto')
    ..addFont(Future.value(read('roboto-regular.ttf')))
    ..addFont(Future.value(read('roboto-medium.ttf')))
    ..addFont(Future.value(read('roboto-bold.ttf')));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(read('materialicons-regular.otf')));
  await icons.load();
}

Future<void> _render(
  WidgetTester tester, {
  required String name,
  required ArrowRingStyle style,
  required bool dark,
}) async {
  debugDisableShadows = false; // otherwise shadows render as solid black shapes in tests
  addTearDown(() => debugDisableShadows = true);
  final key = GlobalKey();
  tester.view.physicalSize = const Size(360, 640) * 1.5;
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);
  final seed = dark ? const Color(0xFF00A67E) : const Color(0xFF3F51B5);
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(colorSchemeSeed: seed, fontFamily: 'Roboto'),
        darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, fontFamily: 'Roboto'),
        home: _NotesApp(style: style, dark: dark),
      ),
    ),
  );
  final out = Directory('build/$name')..createSync(recursive: true);
  for (final f in out.listSync()) {
    f.deleteSync();
  }
  var n = 0;
  Future<void> frames(int ms) async {
    for (var t = 0; t < ms; t += _frameMs) {
      await tester.pump(const Duration(milliseconds: _frameMs));
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/f${(n++).toString().padLeft(4, '0')}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  }

  await frames(700); // the app alone
  unawaited(_tour.start());
  await frames(2600);
  for (var i = 0; i < 3; i++) {
    unawaited(_tour.next());
    await frames(i == 2 ? 2300 : 2600);
  }
  unawaited(_tour.next()); // "Done"
  await frames(900);
}

void unawaited(Future<void> f) {}

void main() {
  testWidgets('render demo frames', (tester) async {
    await _loadFonts();
    await _render(tester, name: 'demo_frames', style: const ArrowRingStyle(), dark: false);
  });

  testWidgets('render style frames', (tester) async {
    await _loadFonts();
    await _render(
      tester,
      name: 'style_frames',
      dark: true,
      style: const ArrowRingStyle(
        color: Color(0xFF2DD4A7),
        labelColor: Color(0xFF06231B),
        labelBackground: Color(0xFF2DD4A7),
        arrowSize: 44,
        ringWidth: 4,
        ringPadding: 10,
        hopDistance: 20,
        downIcon: Icons.south,
        upIcon: Icons.north,
      ),
    );
  });
}
