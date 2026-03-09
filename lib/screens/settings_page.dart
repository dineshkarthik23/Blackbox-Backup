import 'package:flutter/material.dart';
import 'package:black_box/main.dart';   

class SettingsPage extends StatefulWidget {
  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onSave;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SettingsPage({
    super.key,
    required this.preferences,
    required this.onSave,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController ipController;
  late TextEditingController nameController;
  late double timeoutMs;
  late bool autoReconnect;
  late bool hapticsEnabled;
  late int reconnectIntervalSec;

  String? ipError;
  bool _showPassword = false;        
  DateTime? lastSavedAt;
  bool _dirty = false;          

  @override
  void initState() {
    super.initState();
    ipController = TextEditingController();
    nameController = TextEditingController();
    _syncFrom(widget.preferences);
  }

  @override
  void didUpdateWidget(covariant SettingsPage old) {
    super.didUpdateWidget(old);
    if (old.preferences != widget.preferences) _syncFrom(widget.preferences);
  }

  @override
  void dispose() {
    ipController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _syncFrom(AppPreferences p) {
    ipController.text = p.esp32IP;
    nameController.text = p.controllerName;
    timeoutMs = p.commandTimeoutMs.toDouble();
    autoReconnect = p.autoReconnect;
    hapticsEnabled = p.hapticsEnabled;
    reconnectIntervalSec = p.reconnectIntervalSec;
    _dirty = false;
  }

  void _markDirty() => setState(() => _dirty = true);

  bool _validIP(String v) => RegExp(
    r'^((25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(25[0-5]|2[0-4]\d|[01]?\d?\d)$',
  ).hasMatch(v);

  void _save() {
    final ip = ipController.text.trim();
    if (!_validIP(ip)) {
      setState(() => ipError = 'Enter a valid IPv4 address (e.g. 192.168.1.10)');
      return;
    }
    widget.onSave(AppPreferences(
      esp32IP: ip,
      commandTimeoutMs: timeoutMs.round(),
      autoReconnect: autoReconnect,
      hapticsEnabled: hapticsEnabled,
      reconnectIntervalSec: reconnectIntervalSec,
      controllerName: nameController.text.trim().isEmpty
          ? 'Black Box Pilot'
          : nameController.text.trim(),
    ));
    setState(() {
      ipError = null;
      lastSavedAt = DateTime.now();
      _dirty = false;
    });
    _snack('Settings saved ✓', success: true);
  }

  void _restoreDefaults() {
    final d = AppPreferences.defaults;
    widget.onSave(d);
    setState(() {
      _syncFrom(d);
      lastSavedAt = DateTime.now();
    });
    _snack('Default settings restored');
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success
          ? AppColors.success.withValues(alpha: 0.92)
          : null,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────

  Color get _bg => widget.isDarkMode ? AppColors.darkBgBot : AppColors.lightBg;
  Color get _cardBg => widget.isDarkMode
      ? AppColors.darkSurface.withValues(alpha: 0.55)
      : AppColors.lightBgCard;
  Color get _textPrimary => widget.isDarkMode
      ? AppColors.darkTextPrimary
      : AppColors.lightTextPrimary;
  Color get _textMuted => widget.isDarkMode
      ? AppColors.darkTextMuted
      : AppColors.lightTextMuted;
  Color get _accent => widget.isDarkMode
      ? AppColors.darkAccentCyan
      : AppColors.lightAccent;
  Color get _accentAlt => widget.isDarkMode
      ? AppColors.darkAccentTeal
      : AppColors.lightAccentAlt;

  // ── Reusable card wrapper ──────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: widget.isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
      border: Border.all(
        color: widget.isDarkMode
            ? AppColors.darkSurface.withValues(alpha: 0.5)
            : AppColors.lightBorder.withValues(alpha: 0.6),
      ),
    ),
    child: child,
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _accent,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: widget.isDarkMode
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
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          // Dark/light toggle
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: widget.isDarkMode ? AppColors.darkAccentCyan : Colors.white,
            ),
            onPressed: widget.onToggleTheme,
          ),
          // Unsaved-changes save shortcut
          if (_dirty)
            IconButton(
              tooltip: 'Save changes',
              icon: const Icon(Icons.save_outlined),
              onPressed: _save,
            ),
          const SizedBox(width: 4),
        ],
      ),
      backgroundColor: _bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDarkMode
                ? [AppColors.darkBgTop, AppColors.darkBgBot]
                : [AppColors.lightBg, const Color(0xFFDDE8F8)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _buildProfileCard(),
            _buildAppearanceCard(),
            _buildConnectionCard(),
            _buildControlCard(),
            _buildAboutCard(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() => _card(
    child: Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: _accent,
          child: Icon(Icons.sports_esports,
              color: widget.isDarkMode
                  ? AppColors.darkBgBot
                  : Colors.white,
              size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameController.text.isEmpty
                    ? 'Black Box Pilot'
                    : nameController.text,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                'Controller profile',
                style: TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildAppearanceCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Appearance'),
        Row(
          children: [
            Icon(Icons.palette_outlined, color: _accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Theme',
                  style: TextStyle(color: _textPrimary, fontSize: 14)),
            ),
            _themeTogglePill(),
          ],
        ),
      ],
    ),
  );

  Widget _themeTogglePill() {
    final dark = widget.isDarkMode;
    return GestureDetector(
      onTap: widget.onToggleTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 120,
        height: 34,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.4)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 56,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    dark ? Icons.dark_mode : Icons.light_mode,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: dark ? 10 : 66,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  dark ? 'Light' : 'Dark',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Connection'),

        TextField(
          controller: ipController,
          keyboardType: TextInputType.number,
          obscureText: !_showPassword,
          style: TextStyle(color: _textPrimary, fontSize: 14),
          onChanged: (_) {
            _markDirty();
            setState(() => ipError = null);
          },
          decoration: InputDecoration(
            labelText: 'ESP32 IP Address',
            labelStyle: TextStyle(color: _textMuted, fontSize: 13),
            hintText: '192.168.1.10',
            errorText: ipError,
            prefixIcon: Icon(Icons.router_outlined, color: _accent, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: _textMuted,
                size: 18,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.lightSurface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accent.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accent, width: 1.5)),
          ),
        ),

        const SizedBox(height: 18),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Command Timeout',
                style: TextStyle(color: _textPrimary, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${timeoutMs.round()} ms',
                style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Slider(
          value: timeoutMs,
          min: 500,
          max: 5000,
          divisions: 18,
          activeColor: _accent,
          inactiveColor: _textMuted.withValues(alpha: 0.25),
          onChanged: (v) {
            setState(() => timeoutMs = v);
            _markDirty();
          },
        ),

        const SizedBox(height: 4),

        // Auto reconnect
        _switchRow(
          icon: Icons.sync,
          label: 'Auto Reconnect',
          subtitle: 'Periodically ping the ESP32',
          value: autoReconnect,
          activeColor: _accentAlt,
          onChanged: (v) {
            setState(() => autoReconnect = v);
            _markDirty();
          },
        ),

        // Reconnect interval (only shown when autoReconnect is on)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: autoReconnect
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reconnect Interval',
                              style: TextStyle(
                                  color: _textPrimary, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accentAlt.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${reconnectIntervalSec}s',
                              style: TextStyle(
                                  color: _accentAlt,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: reconnectIntervalSec.toDouble(),
                        min: 3,
                        max: 30,
                        divisions: 9,
                        activeColor: _accentAlt,
                        inactiveColor: _textMuted.withValues(alpha: 0.25),
                        onChanged: (v) {
                          setState(() =>
                              reconnectIntervalSec = v.round());
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  // ── Section: Control ───────────────────────────────────────────────────────

  Widget _buildControlCard() => const SizedBox.shrink();

  // ── Section: About ─────────────────────────────────────────────────────────

  Widget _buildAboutCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('About'),
        _infoRow(Icons.directions_car_outlined, 'App', 'Car Control — Black Box'),
        const SizedBox(height: 10),
        _infoRow(Icons.tag, 'Version', '1.2.0'),
        const SizedBox(height: 10),
        _infoRow(Icons.developer_board, 'Target', 'ESP32 (HTTP REST)'),
        const SizedBox(height: 10),
        _infoRow(Icons.wifi, 'Protocol', 'HTTP / Wi-Fi'),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: _accent),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(fontSize: 13, color: _textMuted)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary)),
    ],
  );

  // ── Section: Actions ───────────────────────────────────────────────────────

  Widget _buildActionButtons() => _card(
    child: Column(
      children: [
        // Save
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Settings',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Reset
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _restoreDefaults,
            icon: Icon(Icons.settings_backup_restore_outlined,
                size: 18, color: _textMuted),
            label: Text('Restore Defaults',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _textMuted)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: _textMuted.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Last saved timestamp
        if (lastSavedAt != null) ...[
          const SizedBox(height: 10),
          Text(
            'Last saved at '
            '${lastSavedAt!.hour.toString().padLeft(2, '0')}:'
            '${lastSavedAt!.minute.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ],

        // Unsaved-changes indicator
        if (_dirty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 13,
                  color: widget.isDarkMode
                      ? AppColors.darkAccentAmber
                      : Colors.orange),
              const SizedBox(width: 4),
              Text(
                'You have unsaved changes',
                style: TextStyle(
                    fontSize: 11,
                    color: widget.isDarkMode
                        ? AppColors.darkAccentAmber
                        : Colors.orange),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  // ── Helper: switch row ─────────────────────────────────────────────────────

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: _textMuted)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
