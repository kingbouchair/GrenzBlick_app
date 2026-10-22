import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://ymddwehgifawycwlmtza.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltZGR3ZWhxaWZhd3ljd2xtdHphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1MjY0NzAsImV4cCI6MjEwODEwMjQ3MH0.aU6WqtIDSqgBWLkCIz_f3fCnBH5KEnAcuYILQek60gU';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase Init Info: $e');
  }

  runApp(const GrenzBlickApp());
}

class GrenzBlickApp extends StatelessWidget {
  const GrenzBlickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrenzBlick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF0284C7),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainGatekeeper(),
    );
  }
}

class MainGatekeeper extends StatefulWidget {
  const MainGatekeeper({super.key});

  @override
  State<MainGatekeeper> createState() => _MainGatekeeperState();
}

class _MainGatekeeperState extends State<MainGatekeeper> {
  bool _isOnboarded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnboarded = prefs.getBool('isOnboarded') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
      );
    }
    return _isOnboarded ? const MainNavigationScreen() : const OnboardingScreen();
  }
}

// -----------------------------------------------------------------------------
// ONBOARDING SCREEN
// -----------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _plzController = TextEditingController(text: '5080');
  String _currency = 'CHF';
  double _radius = 15;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plz', _plzController.text);
    await prefs.setString('currency', _currency);
    await prefs.setDouble('radius', _radius);
    await prefs.setBool('isOnboarded', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/logo_banner.png',
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    children: [
                      const Icon(Icons.blur_on, size: 60, color: Color(0xFF0284C7)),
                      Text('GrenzBlick', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('ZWEI LÄNDER. EIN BLICK.', style: GoogleFonts.plusJakartaSans(fontSize: 12, letterSpacing: 2.0, color: Colors.white70)),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Standort-Postleitzahl', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _plzController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: 'z.B. 5080 Laufenburg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Heimwährung', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('CHF (Schweiz)')),
                      selected: _currency == 'CHF',
                      selectedColor: const Color(0xFF0284C7),
                      onSelected: (val) => setState(() => _currency = 'CHF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('EUR (€)')),
                      selected: _currency == 'EUR',
                      selectedColor: const Color(0xFF0284C7),
                      onSelected: (val) => setState(() => _currency = 'EUR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Suchradius: ${_radius.toInt()} km', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Slider(
                value: _radius,
                min: 5,
                max: 30,
                divisions: 5,
                activeColor: const Color(0xFF0284C7),
                onChanged: (val) => setState(() => _radius = val),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _completeOnboarding,
                  child: Text('Jetzt starten', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HAUPT-NAVIGATION (MIT WÄHRUNGSSWITCHER IN TOP-BAR)
// -----------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;
  double _exchangeRate = 0.9261;
  bool _isLoadingRate = false;
  String _activeCurrency = 'CHF'; // 'CHF' oder 'EUR'

  @override
  void initState() {
    super.initState();
    _fetchExchangeRate();
  }

  Future<void> _fetchExchangeRate() async {
    setState(() => _isLoadingRate = true);
    try {
      final res = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/77e851035f91920ec899c579/latest/EUR'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _exchangeRate = (data['conversion_rates']['CHF'] as num).toDouble();
        });
      }
    } catch (_) {}
    setState(() => _isLoadingRate = false);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const AngeboteTab(),
      TankenTab(
        exchangeRate: _exchangeRate,
        onRefreshRate: _fetchExchangeRate,
        isLoadingRate: _isLoadingRate,
        displayCurrency: _activeCurrency,
      ),
      ZollTab(exchangeRate: _exchangeRate),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo_banner.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.blur_on, color: Color(0xFF0284C7)),
              ),
            ),
            const SizedBox(width: 10),
            Text('GrenzBlick', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // WÄHRUNGS-SWITCHER (CHF ⇄ EUR)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _activeCurrency = (_activeCurrency == 'CHF') ? 'EUR' : 'CHF';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0284C7)),
              ),
              child: Row(
                children: [
                  Text(_activeCurrency == 'CHF' ? '🇨🇭 CHF' : '🇪🇺 EUR',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz, size: 14, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isOnboarded', false);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              }
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: Colors.white38,
        backgroundColor: const Color(0xFF1E293B),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Angebote'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station_outlined), activeIcon: Icon(Icons.local_gas_station), label: 'Tanken'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: 'Zoll & Info'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: ANGEBOTE
// -----------------------------------------------------------------------------
class AngeboteTab extends StatelessWidget {
  const AngeboteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, color: Color(0xFF0284C7), size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supermarkt Prospekte DE & CH', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Aldi Süd, Lidl DE, Coop, Migros', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: const Text('🛒 Angebote im Grenzgebiet werden geladen...', style: TextStyle(color: Colors.white70)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: TANKEN (KLICKBARE CARDS + WÄHRUNGSANPASSUNG)
// -----------------------------------------------------------------------------
class TankenTab extends StatefulWidget {
  final double exchangeRate;
  final VoidCallback onRefreshRate;
  final bool isLoadingRate;
  final String displayCurrency;

  const TankenTab({
    super.key,
    required this.exchangeRate,
    required this.onRefreshRate,
    required this.isLoadingRate,
    required this.displayCurrency,
  });

  @override
  State<TankenTab> createState() => _TankenTabState();
}

class _TankenTabState extends State<TankenTab> {
  final String _apiKey = "780326d0-ceae-4fac-aca7-9cf3d194e2de";
  List<Map<String, dynamic>> _allStations = [];
  bool _isLoadingStations = true;

  Map<String, dynamic>? _cheapestE5Station;
  Map<String, dynamic>? _cheapestDieselStation;

  @override
  void initState() {
    super.initState();
    _fetchCombinedStations();
  }

  // Hilfsfunktion: Öffnet Google / Apple Maps
  Future<void> _openMaps(String brand, String street, String place) async {
    final query = Uri.encodeComponent('$brand, $street, $place');
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Karten konnte nicht geöffnet werden: $e');
    }
  }

  Future<void> _fetchCombinedStations() async {
    setState(() {
      _isLoadingStations = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getDouble('radius') ?? 15.0;

    final url = Uri.parse(
      'https://creativecommons.tankerkoenig.de/json/list.php?lat=47.563&lng=8.062&rad=$radius&sort=dist&type=all&apikey=$_apiKey',
    );

    List<Map<String, dynamic>> combined = [];

    // 1. Deutsche Tankstellen von Tankerkönig abrufen
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok'] == true) {
          final List<dynamic> deList = data['stations'] ?? [];
          for (var st in deList) {
            final double? e5EUR = (st['e5'] is num) ? (st['e5'] as num).toDouble() : null;
            final double? dieselEUR = (st['diesel'] is num) ? (st['diesel'] as num).toDouble() : null;
            final double distance = (st['dist'] is num) ? (st['dist'] as num).toDouble() : 5.0;

            combined.add({
              'id': st['id'],
              'brand': st['brand'] ?? st['name'] ?? 'Tankstelle',
              'street': "${st['street'] ?? ''} ${st['houseNumber'] ?? ''}".trim(),
              'place': "${st['place'] ?? ''} (DE)",
              'country': 'DE',
              'isOpen': st['isOpen'] ?? false,
              'hasShop': st['isOpen'] ?? false,
              'dist': distance,
              'e5EUR': e5EUR,
              'dieselEUR': dieselEUR,
              'e5CHF': e5EUR != null ? e5EUR * widget.exchangeRate : null,
              'dieselCHF': dieselEUR != null ? dieselEUR * widget.exchangeRate : null,
            });
          }
        }
      }
    } catch (_) {}

    // 2. Schweizer Tankstellen aus Supabase abrufen
    try {
      final response = await Supabase.instance.client
          .from('swiss_stations')
          .select();

      for (var chSt in response) {
        final double? e5CHF = (chSt['e5_chf'] is num) ? (chSt['e5_chf'] as num).toDouble() : null;
        final double? dieselCHF = (chSt['diesel_chf'] is num) ? (chSt['diesel_chf'] as num).toDouble() : null;

        double dist = 1.2;
        final id = chSt['id'].toString();
        if (id.contains('oil')) dist = 0.5;
        if (id.contains('kaisten')) dist = 3.5;
        if (id.contains('stein')) dist = 5.8;
        if (id.contains('rheinfelden')) dist = 14.2;

        combined.add({
          'id': chSt['id'],
          'brand': chSt['brand'] ?? 'Tankstelle',
          'street': chSt['street'] ?? '',
          'place': chSt['place'] ?? '',
          'country': 'CH',
          'isOpen': chSt['is_open'] ?? true,
          'hasShop': chSt['has_shop'] ?? true,
          'dist': dist,
          'e5CHF': e5CHF,
          'dieselCHF': dieselCHF,
          'e5EUR': e5CHF != null ? e5CHF / widget.exchangeRate : null,
          'dieselEUR': dieselCHF != null ? dieselCHF / widget.exchangeRate : null,
        });
      }
    } catch (e) {
      debugPrint('Supabase Info: $e');
    }

    // Fallback Schweizer Tankstellen inklusive OIL! Laufenburg
    if (combined.where((st) => st['country'] == 'CH').isEmpty) {
      combined.addAll([
        {'id': 'ch_oil_laufenburg', 'brand': 'OIL! tank & go', 'street': 'Baslerstrasse 17', 'place': '5080 Laufenburg (CH)', 'country': 'CH', 'isOpen': true, 'hasShop': false, 'dist': 0.5, 'e5CHF': 2.12, 'dieselCHF': 2.15, 'e5EUR': 2.12 / widget.exchangeRate, 'dieselEUR': 2.15 / widget.exchangeRate},
        {'id': 'ch_avia_laufenburg', 'brand': 'AVIA', 'street': 'Laufenburgerstrasse 30', 'place': '5080 Laufenburg (CH)', 'country': 'CH', 'isOpen': true, 'hasShop': true, 'dist': 0.8, 'e5CHF': 2.13, 'dieselCHF': 2.16, 'e5EUR': 2.13 / widget.exchangeRate, 'dieselEUR': 2.16 / widget.exchangeRate},
        {'id': 'ch_coop_laufenburg', 'brand': 'Coop Pronto', 'street': 'Laufenburgerstrasse 1', 'place': 'Laufenburg (CH)', 'country': 'CH', 'isOpen': true, 'hasShop': true, 'dist': 0.9, 'e5CHF': 1.74, 'dieselCHF': 1.82, 'e5EUR': 1.74 / widget.exchangeRate, 'dieselEUR': 1.82 / widget.exchangeRate},
        {'id': 'ch_agrola_kaisten', 'brand': 'Agrola', 'street': 'Hauptstrasse 45', 'place': 'Kaisten (CH)', 'country': 'CH', 'isOpen': false, 'hasShop': false, 'dist': 3.5, 'e5CHF': 1.72, 'dieselCHF': 1.79, 'e5EUR': 1.72 / widget.exchangeRate, 'dieselEUR': 1.79 / widget.exchangeRate},
        {'id': 'ch_migrol_stein', 'brand': 'Migrol', 'street': 'Schaffhauserstrasse 12', 'place': 'Stein (CH)', 'country': 'CH', 'isOpen': true, 'hasShop': true, 'dist': 5.8, 'e5CHF': 1.75, 'dieselCHF': 1.81, 'e5EUR': 1.75 / widget.exchangeRate, 'dieselEUR': 1.81 / widget.exchangeRate},
      ]);
    }

    combined.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));

    _calculateBestPrices(combined);

    setState(() {
      _allStations = combined;
      _isLoadingStations = false;
    });
  }

  void _calculateBestPrices(List<Map<String, dynamic>> stations) {
    Map<String, dynamic>? bestE5;
    Map<String, dynamic>? bestDiesel;

    for (var st in stations) {
      final double? price = (widget.displayCurrency == 'CHF') ? st['e5CHF'] : st['e5EUR'];
      if (price != null && price > 0) {
        if (bestE5 == null) {
          bestE5 = st;
        } else {
          final double comparePrice = (widget.displayCurrency == 'CHF') ? bestE5['e5CHF'] : bestE5['e5EUR'];
          if (price < comparePrice) bestE5 = st;
        }
      }

      final double? dPrice = (widget.displayCurrency == 'CHF') ? st['dieselCHF'] : st['dieselEUR'];
      if (dPrice != null && dPrice > 0) {
        if (bestDiesel == null) {
          bestDiesel = st;
        } else {
          final double compareDPrice = (widget.displayCurrency == 'CHF') ? bestDiesel['dieselCHF'] : bestDiesel['dieselEUR'];
          if (dPrice < compareDPrice) bestDiesel = st;
        }
      }
    }

    _cheapestE5Station = bestE5;
    _cheapestDieselStation = bestDiesel;
  }

  String _formatPrice(double? val) {
    if (val == null) return 'N/A';
    final prefix = widget.displayCurrency == 'CHF' ? 'CHF ' : '€ ';
    return '$prefix${val.toStringAsFixed(3)}';
  }

  @override
  Widget build(BuildContext context) {
    _calculateBestPrices(_allStations);

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefreshRate();
        await _fetchCombinedStations();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Live Kurs Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_exchange, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Live-Kurs: 1 € = ${widget.exchangeRate.toStringAsFixed(4)} CHF',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: widget.isLoadingRate
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 18, color: Colors.white70),
                  onPressed: () {
                    widget.onRefreshRate();
                    _fetchCombinedStations();
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BESTPREISE BANNER (KLICKBAR ZUM ANNAVIEREN)
          if (!_isLoadingStations && _allStations.isNotEmpty) ...[
            Text('🏆 Gesamtsieger Bestpreise (DE & CH)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Günstigster E5 Kasten
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _cheapestE5Station == null
                        ? null
                        : () => _openMaps(
                              _cheapestE5Station!['brand'],
                              _cheapestE5Station!['street'],
                              _cheapestE5Station!['place'],
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Günstigster Super E5', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              Icon(Icons.navigation, size: 12, color: Color(0xFF10B981)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_cheapestE5Station != null) ...[
                            Text(
                              _formatPrice(widget.displayCurrency == 'CHF' ? _cheapestE5Station!['e5CHF'] : _cheapestE5Station!['e5EUR']),
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                            ),
                            Text(
                              '${_cheapestE5Station!['country'] == 'DE' ? '🇩🇪' : '🇨🇭'} ${_cheapestE5Station!['brand']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else
                            const Text('N/A', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Günstigster Diesel Kasten
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _cheapestDieselStation == null
                        ? null
                        : () => _openMaps(
                              _cheapestDieselStation!['brand'],
                              _cheapestDieselStation!['street'],
                              _cheapestDieselStation!['place'],
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Günstigster Diesel', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              Icon(Icons.navigation, size: 12, color: Color(0xFF0284C7)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_cheapestDieselStation != null) ...[
                            Text(
                              _formatPrice(widget.displayCurrency == 'CHF' ? _cheapestDieselStation!['dieselCHF'] : _cheapestDieselStation!['dieselEUR']),
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                            ),
                            Text(
                              '${_cheapestDieselStation!['country'] == 'DE' ? '🇩🇪' : '🇨🇭'} ${_cheapestDieselStation!['brand']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else
                            const Text('N/A', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Alle Tankstellen (nach Distanz)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                const Text('📍 Nächste zuerst', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          if (_isLoadingStations)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
            )
          else if (_allStations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Keine Tankstellen gefunden.', style: TextStyle(color: Colors.white60)),
            )
          else
            ..._allStations.map((st) {
              final String name = st['brand'];
              final String street = st['street'];
              final String place = st['place'];
              final String country = st['country'];
              final bool hasShop = st['hasShop'];
              final double dist = st['dist'] ?? 0.0;

              final double? e5EUR = st['e5EUR'];
              final double? dieselEUR = st['dieselEUR'];
              final double? e5CHF = st['e5CHF'];
              final double? dieselCHF = st['dieselCHF'];

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openMaps(name, street, place),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(country == 'DE' ? '🇩🇪 DE' : '🇨🇭 CH', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text("$street, $place", style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me, size: 11, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ca. ${dist.toStringAsFixed(1)} km',
                                        style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasShop ? const Color(0xFF10B981).withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hasShop ? 'Shop' : '24/7 Card',
                                    style: TextStyle(
                                      color: hasShop ? const Color(0xFF10B981) : Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 14),

                        // PREIS-BOXEN ANPASSEND AN ACTIVE CURRENCY
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Super E5 / Bleifrei 95', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatPrice(widget.displayCurrency == 'CHF' ? e5CHF : e5EUR),
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF10B981), fontSize: 14),
                                    ),
                                    Text(
                                      widget.displayCurrency == 'CHF'
                                          ? (e5EUR != null ? '€ ${e5EUR.toStringAsFixed(3)}' : '')
                                          : (e5CHF != null ? 'CHF ${e5CHF.toStringAsFixed(3)}' : ''),
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Diesel', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatPrice(widget.displayCurrency == 'CHF' ? dieselCHF : dieselEUR),
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                    ),
                                    Text(
                                      widget.displayCurrency == 'CHF'
                                          ? (dieselEUR != null ? '€ ${dieselEUR.toStringAsFixed(3)}' : '')
                                          : (dieselCHF != null ? 'CHF ${dieselCHF.toStringAsFixed(3)}' : ''),
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ROUTE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF0284C7).withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: const Color(0xFF0F172A),
                            ),
                            onPressed: () => _openMaps(name, street, place),
                            icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF0284C7)),
                            label: Text(
                              'Route in Maps öffnen',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: ZOLL & INFO
// -----------------------------------------------------------------------------
class ZollTab extends StatefulWidget {
  final double exchangeRate;
  const ZollTab({super.key, required this.exchangeRate});

  @override
  State<ZollTab> createState() => _ZollTabState();
}

class _ZollTabState extends State<ZollTab> {
  final _amountEURController = TextEditingController(text: '150');
  double _inputEUR = 150;

  @override
  Widget build(BuildContext context) {
    final mwstDE = _inputEUR - (_inputEUR / 1.19);
    final totalCHF = _inputEUR * widget.exchangeRate;
    final isZollfrei = totalCHF <= 300;
    final chMwSt = isZollfrei ? 0.0 : (totalCHF * 0.081);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0284C7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF0284C7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 GrenzBlick-Tipp: Am Kartenterminal immer in Landeswährung (DE in EUR / CH in CHF) bezahlen – spart bis zu 8% Gebühren!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MwSt- & Zoll-Rechner', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountEURController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Einkaufswert in EUR (€)',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.euro, color: Color(0xFF0284C7)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _inputEUR = double.tryParse(val) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DE MwSt Rückerstattung (19%):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('€ ${mwstDE.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wert in CHF (Live-Kurs):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('CHF ${totalCHF.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isZollfrei ? const Color(0xFF10B981).withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isZollfrei ? const Color(0xFF10B981) : Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      Icon(isZollfrei ? Icons.check_circle : Icons.warning, color: isZollfrei ? const Color(0xFF10B981) : Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isZollfrei ? 'ZOLLFREI IN DIE SCHWEIZ' : 'ZOLLPFLICHTIG (Über 300 CHF)',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isZollfrei ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 13),
                            ),
                            if (!isZollfrei)
                              Text('Schweizer MwSt (8.1%): ca. CHF ${chMwSt.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Freigrenzen pro Person / Tag', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        _buildLimitCard(Icons.restaurant, 'Fleisch & Fleischwaren', '1 kg'),
        _buildLimitCard(Icons.local_drink, 'Alkohol (bis 18 Vol.-%)', '5 Liter'),
        _buildLimitCard(Icons.wine_bar, 'Alkohol (über 18 Vol.-%)', '1 Liter'),
        _buildLimitCard(Icons.smoking_rooms, 'Tabakwaren', '250 Stück Zigaretten'),
        _buildLimitCard(Icons.opacity, 'Butter & Speiseöle', '1 kg / 1 Liter'),
      ],
    );
  }

  Widget _buildLimitCard(IconData icon, String title, String limit) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0284C7)),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
          child: Text(limit, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}