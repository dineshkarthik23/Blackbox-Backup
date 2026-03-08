import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class AppColors {
  static const backgroundTop = Color(0xFF081627);
  static const backgroundBottom = Color(0xFF020912);
  static const appBar = Color(0xFF0E2A47);
  static const surface = Color(0xFF163556);
  static const surfaceSoft = Color(0xFF22486F);

  static const accentCyan = Color(0xFF25D0FF);
  static const accentTeal = Color(0xFF00E5A8);
  static const accentAmber = Color(0xFFFFB703);

  static const success = Color(0xFF52FFB1);
  static const error = Color(0xFFFF627B);

  static const stopPrimary = Color(0xFFFF4D67);
  static const stopSecondary = Color(0xFFB3003C);

  static const textPrimary = Color(0xFFE9F4FF);
  static const textMuted = Color(0xFFA1BDD6);
}

void main() {
  runApp(const CarControlApp());
}

class CarControlApp extends StatelessWidget {
  const CarControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Control App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentCyan,
          brightness: Brightness.dark,
          primary: AppColors.accentCyan,
          secondary: AppColors.accentAmber,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBar,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppPreferences {
  final String esp32IP;
  final int commandTimeoutMs;
  final bool autoReconnect;
  final bool hapticsEnabled;

  const AppPreferences({
    required this.esp32IP,
    required this.commandTimeoutMs,
    required this.autoReconnect,
    required this.hapticsEnabled,
  });

  static const defaults = AppPreferences(
    esp32IP: '10.172.70.213',
    commandTimeoutMs: 1000,
    autoReconnect: true,
    hapticsEnabled: true,
  );

  AppPreferences copyWith({
    String? esp32IP,
    int? commandTimeoutMs,
    bool? autoReconnect,
    bool? hapticsEnabled,
  }) {
    return AppPreferences(
      esp32IP: esp32IP ?? this.esp32IP,
      commandTimeoutMs: commandTimeoutMs ?? this.commandTimeoutMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  AppPreferences preferences = AppPreferences.defaults;

  void updatePreferences(AppPreferences newPreferences) {
    setState(() {
      preferences = newPreferences;
    });
  }

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
          ),
          SettingsPage(
            preferences: preferences,
            onSave: updatePreferences,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
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

class CarControlPage extends StatefulWidget {
  final String esp32IP;
  final Duration commandTimeout;
  final bool autoReconnect;
  final bool hapticsEnabled;

  const CarControlPage({
    super.key,
    required this.esp32IP,
    required this.commandTimeout,
    required this.autoReconnect,
    required this.hapticsEnabled,
  });

  @override
  State<CarControlPage> createState() => _CarControlPageState();
}

class _CarControlPageState extends State<CarControlPage> {
  Timer? autoReconnectTimer;

  String connectionStatus = "Disconnected";
  bool isConnected = false;
  String lastCommand = "STOP";
  
  @override
  void initState() {
    super.initState();
    checkConnection();
    configureAutoReconnect();
  }

  @override
  void didUpdateWidget(covariant CarControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.autoReconnect != widget.autoReconnect) {
      configureAutoReconnect();
    }

    if (oldWidget.esp32IP != widget.esp32IP) {
      checkConnection();
    }
  }

  @override
  void dispose() {
    autoReconnectTimer?.cancel();
    super.dispose();
  }

  void configureAutoReconnect() {
    autoReconnectTimer?.cancel();
    if (widget.autoReconnect) {
      autoReconnectTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        checkConnection();
      });
    }
  }

  Future<void> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('http://${widget.esp32IP}/stop'))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        setState(() {
          connectionStatus = "Connected to ESP32";
          isConnected = true;
        });
      } else {
        setState(() {
          connectionStatus = "ESP32 Error";
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = "ESP32 Not Found";
        isConnected = false;
      });
    }
  }


  Future<void> sendCommand(String command) async {
    try {
      final url = 'http://${widget.esp32IP}/$command';
      final response = await http.get(Uri.parse(url)).timeout(widget.commandTimeout);
      
      setState(() {
        lastCommand = response.body; 
        if (!isConnected) {
          isConnected = true;
          connectionStatus = "Connected to ESP32";
        }
      });
    } catch (e) {
      setState(() {
        connectionStatus = "Connection Failed";
        isConnected = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send command: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? AppColors.success : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Car Control App - Black Box',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: statusColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.surfaceSoft.withValues(alpha: 0.48),
                              AppColors.surface.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isConnected ? Icons.wifi : Icons.wifi_off,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      connectionStatus,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: checkConnection,
                                  color: AppColors.accentCyan,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Last Command:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  lastCommand,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ControlButton(
                                icon: Icons.arrow_upward,
                                label: 'FORWARD',
                                onPressed: () => sendCommand('forward'),
                                color: AppColors.accentTeal,
                                hapticsEnabled: widget.hapticsEnabled,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ControlButton(
                                    icon: Icons.arrow_back,
                                    label: 'LEFT',
                                    onPressed: () => sendCommand('left'),
                                    color: AppColors.accentAmber,
                                    hapticsEnabled: widget.hapticsEnabled,
                                  ),
                                  const SizedBox(width: 24),
                                  ControlButton(
                                    icon: Icons.arrow_forward,
                                    label: 'RIGHT',
                                    onPressed: () => sendCommand('right'),
                                    color: AppColors.accentCyan,
                                    hapticsEnabled: widget.hapticsEnabled,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              ControlButton(
                                icon: Icons.arrow_downward,
                                label: 'BACKWARD',
                                onPressed: () => sendCommand('backward'),
                                color: const Color(0xFF4A8CFF),
                                hapticsEnabled: widget.hapticsEnabled,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              StopButton(
                                onPressed: () => sendCommand('stop'),
                                hapticsEnabled: widget.hapticsEnabled,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.memory,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ESP32: ${widget.esp32IP}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onSave;

  const SettingsPage({
    super.key,
    required this.preferences,
    required this.onSave,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController ipController;
  late double timeoutMs;
  late bool autoReconnect;
  late bool hapticsEnabled;

  String? ipError;
  DateTime? lastSavedAt;

  @override
  void initState() {
    super.initState();
    ipController = TextEditingController();
    syncFromPreferences(widget.preferences);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.esp32IP != widget.preferences.esp32IP ||
        oldWidget.preferences.commandTimeoutMs != widget.preferences.commandTimeoutMs ||
        oldWidget.preferences.autoReconnect != widget.preferences.autoReconnect ||
        oldWidget.preferences.hapticsEnabled != widget.preferences.hapticsEnabled) {
      syncFromPreferences(widget.preferences);
    }
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }

  void syncFromPreferences(AppPreferences preferences) {
    ipController.text = preferences.esp32IP;
    timeoutMs = preferences.commandTimeoutMs.toDouble();
    autoReconnect = preferences.autoReconnect;
    hapticsEnabled = preferences.hapticsEnabled;
  }

  bool isValidIpv4(String value) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(25[0-5]|2[0-4]\d|[01]?\d?\d)$',
    );
    return ipRegex.hasMatch(value);
  }

  void saveSettings() {
    final ip = ipController.text.trim();
    if (!isValidIpv4(ip)) {
      setState(() {
        ipError = 'Enter a valid IPv4 address (example: 192.168.1.10)';
      });
      return;
    }

    widget.onSave(
      AppPreferences(
        esp32IP: ip,
        commandTimeoutMs: timeoutMs.round(),
        autoReconnect: autoReconnect,
        hapticsEnabled: hapticsEnabled,
      ),
    );

    setState(() {
      ipError = null;
      lastSavedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  void restoreDefaults() {
    final defaults = AppPreferences.defaults;
    widget.onSave(defaults);
    setState(() {
      syncFromPreferences(defaults);
      ipError = null;
      lastSavedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default settings restored')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundBottom,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.24),
                ),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accentCyan,
                    child: Icon(Icons.person, color: AppColors.backgroundBottom),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Black Box Pilot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fine-tune connection and control experience',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ipController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP Address',
                      hintText: '192.168.1.10',
                      errorText: ipError,
                      prefixIcon: const Icon(Icons.router, color: AppColors.accentCyan),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Command Timeout: ${timeoutMs.round()} ms',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  Slider(
                    value: timeoutMs,
                    min: 500,
                    max: 5000,
                    divisions: 18,
                    activeColor: AppColors.accentCyan,
                    inactiveColor: AppColors.textMuted.withValues(alpha: 0.35),
                    label: '${timeoutMs.round()} ms',
                    onChanged: (value) {
                      setState(() {
                        timeoutMs = value;
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: autoReconnect,
                    activeColor: AppColors.accentTeal,
                    title: const Text(
                      'Auto Reconnect',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: const Text(
                      'Refresh connection every 8 seconds on Home tab',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    onChanged: (value) {
                      setState(() {
                        autoReconnect = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile.adaptive(
                value: hapticsEnabled,
                activeColor: AppColors.accentAmber,
                title: const Text(
                  'Haptic Feedback',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Vibration feedback when pressing control buttons',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (value) {
                  setState(() {
                    hapticsEnabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: saveSettings,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: AppColors.backgroundBottom,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: restoreDefaults,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restore Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.textMuted.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  if (lastSavedAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Last updated: ${lastSavedAt!.hour.toString().padLeft(2, '0')}:${lastSavedAt!.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool hapticsEnabled;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.hapticsEnabled,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => isPressed = true);
        if (widget.hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() => isPressed = false);
      },
      onTapCancel: () {
        setState(() => isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPressed
                ? [widget.color.withValues(alpha: 0.78), widget.color]
                : [widget.color, widget.color.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 36,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
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
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => isPressed = true);
        if (widget.hapticsEnabled) {
          HapticFeedback.heavyImpact();
        }
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() => isPressed = false);
      },
      onTapCancel: () {
        setState(() => isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPressed
                ? [AppColors.stopSecondary, AppColors.stopPrimary]
                : [AppColors.stopPrimary, AppColors.stopSecondary],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.stopPrimary.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stop_circle_outlined,
              size: 50,
              color: Colors.white,
            ),
            SizedBox(height: 6),
            Text(
              'STOP',
              style: TextStyle(
                fontSize: 18,
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
