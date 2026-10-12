import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'models/cotizacion.dart';
import 'models/empresa.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cotizador_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TmApp());
}

class TmApp extends StatelessWidget {
  const TmApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'T&M Cotizador',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const RootGate(),
      );
}

/// Decide entre onboarding (primera vez) y la app principal.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final _store = StorageService();
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final first = await _store.isFirstRun();
    if (!mounted) return;
    setState(() => _showOnboarding = first);
  }

  Future<void> _finishOnboarding() async {
    await _store.completeOnboarding();
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_showOnboarding == true) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _storage = StorageService();
  int _tab = 0;
  AppPrecios _precios = const AppPrecios();
  Empresa _empresa = const Empresa();
  int _refreshKey = 0; // sube cada vez que se guarda una cotización
  Cotizacion? _prefill;
  int _prefillToken = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final p = await _storage.loadPrecios();
    final e = await _storage.loadEmpresa();
    if (!mounted) return;
    setState(() {
      _precios = p;
      _empresa = e;
    });
  }

  void _onPreciosUpdated(AppPrecios p) => setState(() => _precios = p);

  void _onEmpresaUpdated(Empresa e) => setState(() => _empresa = e);

  void _onGuardado() {
    setState(() {
      _refreshKey++; // dispara recarga de stats y del historial
      _tab = 2;      // va al historial
    });
  }

  void _duplicar(Cotizacion c) {
    setState(() {
      _prefill = c;
      _prefillToken++;
      _tab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Inicio', 'Cotizar', 'Historial', 'Config'];
    final icons = [
      Icons.home_rounded,
      Icons.calculate_rounded,
      Icons.folder_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'T&M',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ['Inicio', 'Nueva Cotización', 'Historial', 'Configuración'][_tab],
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            precios: _precios,
            onCotizar: () => setState(() => _tab = 1),
            onHistorial: () => setState(() => _tab = 2),
            refreshKey: _refreshKey,
          ),
          CotizadorScreen(
            precios: _precios,
            onGuardado: _onGuardado,
            prefill: _prefill,
            prefillToken: _prefillToken,
          ),
          HistorialScreen(
            key: ValueKey(_refreshKey),
            empresa: _empresa,
            onDuplicar: _duplicar,
          ),
          ConfigScreen(
            precios: _precios,
            empresa: _empresa,
            onSaved: _onPreciosUpdated,
            onEmpresaSaved: _onEmpresaUpdated,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: List.generate(
            4,
            (i) => BottomNavigationBarItem(
              icon: Icon(icons[i]),
              label: labels[i],
            ),
          ),
        ),
      ),
    );
  }
}
