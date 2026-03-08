import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:black_box/screens/settings_page.dart';

class AppColors {
  static const lightBg          = Color(0xFFF4F7FB);
  static const lightBgCard      = Color(0xFFFFFFFF);
  static const lightHeaderTop   = Color(0xFF1565C0);
  static const lightHeaderBot   = Color(0xFF0D47A1);
  static const lightSurface     = Color(0xFFE8F0FE);
  static const lightBorder      = Color(0xFFBBCEF5);
  static const lightTextPrimary = Color(0xFF0D1B3E);
  static const lightTextMuted   = Color(0xFF5A7196);
  static const lightAccent      = Color(0xFF1976D2);
  static const lightAccentAlt   = Color(0xFF0288D1);

  static const darkBgTop        = Color(0xFF081627);
  static const darkBgBot        = Color(0xFF020912);
  static const darkAppBar       = Color(0xFF0E2A47);
  static const darkSurface      = Color(0xFF163556);
  static const darkSurfaceSoft  = Color(0xFF22486F);
  static const darkAccentCyan   = Color(0xFF25D0FF);
  static const darkAccentTeal   = Color(0xFF00E5A8);
  static const darkAccentAmber  = Color(0xFFFFB703);
  static const darkTextPrimary  = Color(0xFFE9F4FF);
  static const darkTextMuted    = Color(0xFFA1BDD6);

  static const success          = Color(0xFF2ECC71);
  static const error            = Color(0xFFFF4C67);
  static const stopPrimary      = Color(0xFFFF4D67);
  static const stopSecondary    = Color(0xFFB3003C);

  static const btnLight         = Color(0xFF1976D2);
  static const btnDark          = Color(0xFF25D0FF);
}


ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBg,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightAccent,
    secondary: AppColors.lightAccentAlt,
    surface: AppColors.lightBgCard,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightHeaderTop,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.lightSurface,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.lightAccent.withValues(alpha: 0.92),
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
  useMaterial3: true,
);

ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBgBot,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.darkAccentCyan,
    brightness: Brightness.dark,
    primary: AppColors.darkAccentCyan,
    secondary: AppColors.darkAccentAmber,
    surface: AppColors.darkSurface,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkAppBar,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: true,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkAppBar,
    indicatorColor: AppColors.darkSurfaceSoft,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.error.withValues(alpha: 0.9),
    contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
  useMaterial3: true,
);

// ─── Entry Point ──────────────────────────────────────────────────────────────

void main() {
  runApp(const CarControlApp());
}

class CarControlApp extends StatefulWidget {
  const CarControlApp({super.key});

  @override
  State<CarControlApp> createState() => _CarControlAppState();

  /// Allow descendants to call toggleTheme / read isDark via this helper.
  static _CarControlAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_CarControlAppState>()!;
}

class _CarControlAppState extends State<CarControlApp> {
  bool isDarkMode = true;   // default: dark

  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Control App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AppShell(isDarkMode: isDarkMode, onToggleTheme: toggleTheme),
    );
  }
}

// ─── Preferences Model ────────────────────────────────────────────────────────

class AppPreferences {
  final String esp32IP;
  final int commandTimeoutMs;
  final bool autoReconnect;
  final bool hapticsEnabled;
  final int reconnectIntervalSec;
  final String controllerName;

  const AppPreferences({
    required this.esp32IP,
    required this.commandTimeoutMs,
    required this.autoReconnect,
    required this.hapticsEnabled,
    required this.reconnectIntervalSec,
    required this.controllerName,
  });

  static const defaults = AppPreferences(
    esp32IP: '10.172.70.213',
    commandTimeoutMs: 1000,
    autoReconnect: true,
    hapticsEnabled: true,
    reconnectIntervalSec: 8,
    controllerName: 'Black Box Pilot',
  );

  AppPreferences copyWith({
    String? esp32IP,
    int? commandTimeoutMs,
    bool? autoReconnect,
    bool? hapticsEnabled,
    int? reconnectIntervalSec,
    String? controllerName,
  }) {
    return AppPreferences(
      esp32IP: esp32IP ?? this.esp32IP,
      commandTimeoutMs: commandTimeoutMs ?? this.commandTimeoutMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reconnectIntervalSec: reconnectIntervalSec ?? this.reconnectIntervalSec,
      controllerName: controllerName ?? this.controllerName,
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AppShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  AppPreferences preferences = AppPreferences.defaults;

  void updatePreferences(AppPreferences newPreferences) =>
      setState(() => preferences = newPreferences);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: [
          CarControlPage(
            esp32IP: preferences.esp32IP,
            commandTimeout: Duration(milliseconds: preferences.commandTimeoutMs),
            autoReconnect: preferences.autoReconnect,
            hapticsEnabled: preferences.hapticsEnabled,
            reconnectIntervalSec: preferences.reconnectIntervalSec,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
          SettingsPage(
            preferences: preferences,
            onSave: updatePreferences,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (i) => setState(() => selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── Car Control Page ─────────────────────────────────────────────────────────

class CarControlPage extends StatefulWidget {
  final String esp32IP;
  final Duration commandTimeout;
  final bool autoReconnect;
  final bool hapticsEnabled;
  final int reconnectIntervalSec;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const CarControlPage({
    super.key,
    required this.esp32IP,
    required this.commandTimeout,
    required this.autoReconnect,
    required this.hapticsEnabled,
    required this.reconnectIntervalSec,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<CarControlPage> createState() => _CarControlPageState();
}

class _CarControlPageState extends State<CarControlPage> {
  Timer? autoReconnectTimer;
  String connectionStatus = 'Disconnected';
  bool isConnected = false;
  String lastCommand = 'STOP';

  @override
  void initState() {
    super.initState();
    checkConnection();
    _configureReconnect();
  }

  @override
  void didUpdateWidget(covariant CarControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoReconnect != widget.autoReconnect ||
        oldWidget.reconnectIntervalSec != widget.reconnectIntervalSec) {
      _configureReconnect();
    }
    if (oldWidget.esp32IP != widget.esp32IP) checkConnection();
  }

  @override
  void dispose() {
    autoReconnectTimer?.cancel();
    super.dispose();
  }

  void _configureReconnect() {
    autoReconnectTimer?.cancel();
    if (widget.autoReconnect) {
      autoReconnectTimer = Timer.periodic(
        Duration(seconds: widget.reconnectIntervalSec),
        (_) => checkConnection(),
      );
    }
  }

  Future<void> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('http://${widget.esp32IP}/stop'))
          .timeout(const Duration(seconds: 3));
      setState(() {
        isConnected = response.statusCode == 200;
        connectionStatus =
            isConnected ? 'Connected to ESP32' : 'ESP32 Error';
      });
    } catch (_) {
      setState(() {
        isConnected = false;
        connectionStatus = 'ESP32 Not Found';
      });
    }
  }

  Future<void> sendCommand(String command) async {
    try {
      final response = await http
          .get(Uri.parse('http://${widget.esp32IP}/$command'))
          .timeout(widget.commandTimeout);
      setState(() {
        lastCommand = response.body;
        if (!isConnected) {
          isConnected = true;
          connectionStatus = 'Connected to ESP32';
        }
      });
    } catch (e) {
      setState(() {
        connectionStatus = 'Connection Failed';
        isConnected = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command failed: $e'),
              duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final statusColor = isConnected ? AppColors.success : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: dark
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightHeaderTop, AppColors.lightHeaderBot],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
        title: const Text(
          'Car Control — Black Box',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(dark),
                color: dark ? AppColors.darkAccentCyan : Colors.white,
              ),
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(dark, statusColor),
    );
  }

  Widget _buildBody(bool dark, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [AppColors.darkBgTop, AppColors.darkBgBot]
              : [AppColors.lightBg, const Color(0xFFDDE8F8)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight - 80,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _buildStatusCard(dark, statusColor),
                  Expanded(child: _buildControlPad(dark)),
                  _buildFooterChip(dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────────

  Widget _buildStatusCard(bool dark, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurface.withValues(alpha: 0.62)
              : AppColors.lightBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: dark ? 0.18 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connectionStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last: $lastCommand',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  size: 20,
                  color: dark
                      ? AppColors.darkAccentCyan
                      : AppColors.lightAccent),
              onPressed: checkConnection,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ── D-pad control ──────────────────────────────────────────────────────────

  Widget _buildControlPad(bool dark) {
    final btnColor = dark ? AppColors.btnDark : AppColors.btnLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ControlButton(
              icon: Icons.arrow_upward_rounded,
              label: 'FORWARD',
              onPressed: () => sendCommand('forward'),
              color: btnColor,
              isDark: dark,
              hapticsEnabled: widget.hapticsEnabled,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ControlButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'LEFT',
                  onPressed: () => sendCommand('left'),
                  color: btnColor,
                  isDark: dark,
                  hapticsEnabled: widget.hapticsEnabled,
                ),
                const SizedBox(width: 28),
                StopButton(
                  onPressed: () => sendCommand('stop'),
                  hapticsEnabled: widget.hapticsEnabled,
                ),
                const SizedBox(width: 28),
                ControlButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'RIGHT',
                  onPressed: () => sendCommand('right'),
                  color: btnColor,
                  isDark: dark,
                  hapticsEnabled: widget.hapticsEnabled,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ControlButton(
              icon: Icons.arrow_downward_rounded,
              label: 'BACKWARD',
              onPressed: () => sendCommand('backward'),
              color: btnColor,
              isDark: dark,
              hapticsEnabled: widget.hapticsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer chip ────────────────────────────────────────────────────────────

  Widget _buildFooterChip(bool dark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurface.withValues(alpha: 0.35)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dark
                ? AppColors.darkAccentCyan.withValues(alpha: 0.18)
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory,
                size: 14,
                color: dark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted),
            const SizedBox(width: 6),
            Text(
              'ESP32: ${widget.esp32IP}',
              style: TextStyle(
                fontSize: 11,
                color: dark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control Button ───────────────────────────────────────────────────────────

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isDark;
  final bool hapticsEnabled;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.isDark,
    required this.hapticsEnabled,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? widget.color.withValues(alpha: _pressed ? 0.95 : 0.78)
        : widget.color.withValues(alpha: _pressed ? 1.0 : 0.85);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        if (widget.hapticsEnabled) HapticFeedback.selectionClick();
        widget.onPressed();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.14)
                : widget.color.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withValues(
                        alpha: widget.isDark ? 0.45 : 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 34,
                color: widget.isDark ? Colors.white : Colors.white),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stop Button ──────────────────────────────────────────────────────────────

class StopButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool hapticsEnabled;

  const StopButton({
    super.key,
    required this.onPressed,
    required this.hapticsEnabled,
  });

  @override
  State<StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<StopButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        if (widget.hapticsEnabled) HapticFeedback.heavyImpact();
        widget.onPressed();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? [AppColors.stopSecondary, AppColors.stopPrimary]
                : [AppColors.stopPrimary, AppColors.stopSecondary],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.stopPrimary.withValues(alpha: 0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop_circle_outlined, size: 42, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'STOP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}