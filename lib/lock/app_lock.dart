import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';

final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 20000, bits: 256);
final _localAuth = LocalAuthentication();
const _windowChannel = MethodChannel('whatseat/window');

Future<String> _hash(String pin, List<int> salt) async {
  final key = await _pbkdf2.deriveKeyFromPassword(password: pin, nonce: salt);
  return base64Encode(await key.extractBytes());
}

Future<void> savePin(String pin) async {
  final random = Random.secure();
  final salt = List.generate(16, (_) => random.nextInt(256));
  await secureStorage.write(key: 'pin_salt', value: base64Encode(salt));
  await secureStorage.write(key: 'pin_hash', value: await _hash(pin, salt));
}

Future<bool> verifyPin(String pin) async {
  final salt = await secureStorage.read(key: 'pin_salt');
  final hash = await secureStorage.read(key: 'pin_hash');
  if (salt == null || hash == null) return false;
  return await _hash(pin, base64Decode(salt)) == hash;
}

Future<void> clearPin() async {
  await secureStorage.delete(key: 'pin_salt');
  await secureStorage.delete(key: 'pin_hash');
}

Future<bool> biometricsAvailable() async {
  try {
    return await _localAuth.isDeviceSupported() && await _localAuth.canCheckBiometrics;
  } on PlatformException {
    return false;
  }
}

Future<bool> authenticateBiometric(String reason) async {
  try {
    return await _localAuth.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  } catch (_) {
    return false;
  }
}

int _suspended = 0;

/// For flows that leave the app on purpose (share sheet, file picker), which would otherwise re-lock it.
Future<T> withoutRelock<T>(Future<T> Function() action) async {
  _suspended++;
  try {
    return await action();
  } finally {
    _suspended--;
  }
}

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = ref.read(settingsProvider).lockEnabled;
  bool _obscured = false;
  DateTime? _leftAt;
  bool _leftForFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applySecureWindow(_locked);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _applySecureWindow(bool secure) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _windowChannel.invokeMethod('setSecure', secure);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    if (!settings.lockEnabled) return;
    switch (state) {
      case AppLifecycleState.inactive:
        if (_suspended == 0) setState(() => _obscured = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_leftAt == null) {
          _leftAt = DateTime.now();
          _leftForFlow = _suspended > 0;
        }
        if (_suspended == 0) setState(() => _obscured = true);
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        // Trips to the share sheet or file picker get a grace period instead of locking on return,
        // but staying away longer still locks.
        final timeout = _leftForFlow ? max(settings.lockTimeoutSeconds, 300) : settings.lockTimeoutSeconds;
        setState(() {
          _obscured = false;
          if (leftAt != null && DateTime.now().difference(leftAt).inSeconds >= timeout) {
            _locked = true;
          }
        });
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((s) => s.lockEnabled), (_, enabled) => _applySecureWindow(enabled));
    return Stack(
      fit: StackFit.expand,
      children: [
        // ExcludeFocus: a hardware keyboard could otherwise still type into a hidden text field.
        ExcludeFocus(excluding: _locked, child: Offstage(offstage: _locked, child: widget.child)),
        if (_locked)
          LockScreen(onUnlocked: () => setState(() => _locked = false))
        else if (_obscured)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              child: Center(child: Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary)),
            ),
          ),
      ],
    );
  }
}

/// Asks for the current PIN (or biometrics) before security settings change.
Future<bool> confirmPin(BuildContext context) async {
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(),
        body: LockScreen(
          title: AppLocalizations.of(context).pinConfirm,
          onUnlocked: () => Navigator.pop(context, true),
        ),
      ),
    ),
  );
  return ok ?? false;
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked, this.title});

  final VoidCallback onUnlocked;
  final String? title;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _error = false;
  bool _checking = false;
  Timer? _countdown;

  SharedPreferencesWithCache get _prefs => ref.read(prefsProvider);

  // Persisted, so killing the app doesn't reset the throttle.
  int get _remainingBlock {
    final until = _prefs.getInt('pinBlockedUntil') ?? 0;
    return ((until - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_remainingBlock <= 0) return;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingBlock <= 0) t.cancel();
      setState(() {});
    });
  }

  Future<void> _registerFailure() async {
    final failures = (_prefs.getInt('pinFailures') ?? 0) + 1;
    await _prefs.setInt('pinFailures', failures);
    if (failures >= 5) {
      final seconds = min(30 * pow(2, failures - 5).toInt(), 3600);
      await _prefs.setInt('pinBlockedUntil', DateTime.now().millisecondsSinceEpoch + seconds * 1000);
      _startCountdown();
    }
  }

  Future<void> _unlock() async {
    await _prefs.setInt('pinFailures', 0);
    widget.onUnlocked();
  }

  Future<void> _tryBiometric() async {
    if (!ref.read(settingsProvider).biometricEnabled || !mounted) return;
    if (await authenticateBiometric(AppLocalizations.of(context).unlockReason)) await _unlock();
  }

  Future<void> _onChanged(String pin) async {
    if (_remainingBlock > 0 || _checking) return;
    setState(() {
      _pin = pin;
      _error = false;
    });
    if (pin.length < ref.read(settingsProvider).pinLength) return;
    _checking = true;
    final ok = await verifyPin(pin);
    _checking = false;
    if (ok) {
      await _unlock();
    } else {
      await _registerFailure();
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final blocked = _remainingBlock;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: PinPad(
          title: widget.title ?? l.lockTitle,
          subtitle: blocked > 0 ? l.pinBlocked(blocked) : (_error ? l.pinWrong : l.pinEnter),
          isError: _error || blocked > 0,
          pin: _pin,
          maxLength: settings.pinLength,
          onChanged: _onChanged,
          onBiometric: settings.biometricEnabled ? _tryBiometric : null,
        ),
      ),
    );
  }
}

/// Returns the chosen PIN length, or null when cancelled.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String? _first;
  bool _mismatch = false;

  Future<void> _onChanged(String pin) async {
    setState(() {
      _pin = pin;
      _mismatch = false;
    });
    final first = _first;
    if (first == null || pin.length < first.length) return;
    if (pin == first) {
      await savePin(pin);
      if (mounted) Navigator.pop(context, pin.length);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _first = null;
        _pin = '';
        _mismatch = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final confirming = _first != null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: PinPad(
          title: confirming ? l.pinRepeat : l.pinChoose,
          subtitle: _mismatch ? l.pinMismatch : l.pinLengthHint,
          isError: _mismatch,
          pin: _pin,
          maxLength: confirming ? _first!.length : 6,
          onChanged: _onChanged,
          onSubmit: !confirming && _pin.length >= 4
              ? () => setState(() {
                    _first = _pin;
                    _pin = '';
                  })
              : null,
        ),
      ),
    );
  }
}

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pin,
    required this.maxLength,
    required this.onChanged,
    this.isError = false,
    this.onBiometric,
    this.onSubmit,
  });

  final String title;
  final String subtitle;
  final String pin;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool isError;
  final VoidCallback? onBiometric;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget key(String digit) => _PadButton(
          onTap: pin.length < maxLength ? () => onChanged(pin + digit) : null,
          child: Text(digit, style: text.headlineMedium),
        );

    return Column(
      children: [
        const Spacer(),
        Icon(Icons.lock_rounded, size: 40, color: scheme.primary),
        const SizedBox(height: 16),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle,
            style: text.bodyMedium?.copyWith(color: isError ? scheme.error : scheme.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < maxLength; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < pin.length ? (isError ? scheme.error : scheme.primary) : Colors.transparent,
                  border: Border.all(color: isError ? scheme.error : scheme.outline, width: 1.5),
                ),
              ),
          ],
        ),
        const Spacer(),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) key(d)]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onSubmit != null)
              _PadButton(onTap: onSubmit, child: const Icon(Icons.check_rounded))
            else if (onBiometric != null)
              _PadButton(onTap: onBiometric, child: const Icon(Icons.fingerprint_rounded))
            else
              const _PadButton(child: SizedBox()),
            key('0'),
            _PadButton(
              onTap: pin.isEmpty ? null : () => onChanged(pin.substring(0, pin.length - 1)),
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Material(
          color: onTap == null ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}
