import 'package:flutter/material.dart';
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
      home: const CarControlPage(),
    );
  }
}

class CarControlPage extends StatefulWidget {
  const CarControlPage({super.key});

  @override
  State<CarControlPage> createState() => _CarControlPageState();
}

class _CarControlPageState extends State<CarControlPage> {
  String esp32IP = "10.172.70.213"; 
  
  String connectionStatus = "Disconnected";
  bool isConnected = false;
  String lastCommand = "STOP";
  
  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  Future<void> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('http://$esp32IP/stop'))
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
      final url = 'http://$esp32IP/$command';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 1));
      
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
                                  ),
                                  const SizedBox(width: 24),
                                  ControlButton(
                                    icon: Icons.arrow_forward,
                                    label: 'RIGHT',
                                    onPressed: () => sendCommand('right'),
                                    color: AppColors.accentCyan,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              ControlButton(
                                icon: Icons.arrow_downward,
                                label: 'BACKWARD',
                                onPressed: () => sendCommand('backward'),
                                color: const Color(0xFF4A8CFF),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              StopButton(
                                onPressed: () => sendCommand('stop'),
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
                              'ESP32: $esp32IP',
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

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
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

  const StopButton({
    super.key,
    required this.onPressed,
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
