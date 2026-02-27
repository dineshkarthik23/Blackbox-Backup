import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
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
  String esp32IP = "10.233.100.213"; 
  
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Car Control App - Black Box',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F3460),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F3460),
              const Color(0xFF1A1A2E),
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected ? Colors.green : Colors.red,
                            width: 2,
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
                                      color: isConnected ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      connectionStatus,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isConnected ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: checkConnection,
                                  color: Colors.white,
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
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  lastCommand,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
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
                                color: Colors.green,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ControlButton(
                                    icon: Icons.arrow_back,
                                    label: 'LEFT',
                                    onPressed: () => sendCommand('left'),
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 24),
                                  ControlButton(
                                    icon: Icons.arrow_forward,
                                    label: 'RIGHT',
                                    onPressed: () => sendCommand('right'),
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              ControlButton(
                                icon: Icons.arrow_downward,
                                label: 'BACKWARD',
                                onPressed: () => sendCommand('backward'),
                                color: Colors.blue,
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
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.memory,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ESP32: $esp32IP',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
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
                ? [widget.color.withOpacity(0.8), widget.color]
                : [widget.color, widget.color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                ? [Colors.red.shade700, Colors.red.shade900]
                : [Colors.red, Colors.red.shade700],
          ),
          shape: BoxShape.circle,
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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