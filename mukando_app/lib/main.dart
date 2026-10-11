import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'celebration.dart';
import 'circle_view.dart';
import 'ledger_screen.dart';
import 'member_sheet.dart';
import 'members_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Palette.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MukandoChainApp());
}

class MukandoChainApp extends StatelessWidget {
  const MukandoChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MukandoChain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: const ColorScheme.dark(
          primary: Palette.emerald,
          secondary: Palette.cyan,
        ),
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  SavingsCircle? _d;
  bool _offline = false;
  Timer? _timer;
  int _tab = 0;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final d = await Api.fetch();
      if (!mounted) return;
      setState(() {
        _d = d;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _offline = true);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ));
  }

  Future<bool> _call(String path, {String? ok}) async {
    try {
      await Api.post(path);
      HapticFeedback.mediumImpact();
      if (ok != null) _snack(ok);
      await _refresh();
      return true;
    } on ApiError catch (e) {
      _snack(e.message);
      return false;
    } catch (_) {
      _snack("Couldn't reach the server.");
      return false;
    }
  }

  void _openMember(Member m) {
    final d = _d;
    if (d == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedId = m.id);
    showMemberSheet(
      context: context,
      member: m,
      circle: d,
      onRecord: () => _call(
        '/api/members/${m.id}/contribute',
        ok: "${m.name}'s ${money(d.contribution)} payment recorded",
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  Future<void> _payout(SavingsCircle d) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1820),
        title: Text('Release ${money(d.pot)}?'),
        content: Text(
          '${d.recipientName} will receive the pot. '
          'This is written to the ledger and cannot be edited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.gold,
              foregroundColor: Palette.bg,
            ),
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (go != true) return;
    final name = d.recipientName;
    final amount = d.pot;
    if (await _call('/api/payout')) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      showCelebration(
          context, '${money(amount)} released', '$name receives this cycle\'s pot');
    }
  }

  void _howItWorks() {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Palette.emerald),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Palette.text, fontWeight: FontWeight.w700)),
                    Text(body,
                        style: const TextStyle(
                            color: Palette.dim, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1820),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Palette.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOW IT WORKS',
                style: TextStyle(
                    color: Palette.cyan, letterSpacing: 3, fontSize: 12)),
            const SizedBox(height: 16),
            point(Icons.touch_app, 'Tap a member to record a payment',
                'Every member pays the same amount each cycle. One member receives the whole pot, in turn.'),
            point(Icons.link, 'Every record is linked to the one before',
                'Like links in a chain. Change an old record and the chain breaks.'),
            point(Icons.verified_user, 'Anyone can check',
                'Open the Ledger tab and tap Verify now. All members see the same records.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              if (_offline)
                Container(
                  width: double.infinity,
                  color: const Color(0x33FF4D6D),
                  padding: const EdgeInsets.all(6),
                  child: const Text('Offline: trying to reconnect…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Palette.red, fontSize: 12)),
                ),
              Expanded(
                child: d == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Palette.emerald),
                            SizedBox(height: 14),
                            Text('Opening your circle…',
                                style: TextStyle(color: Palette.dim)),
                          ],
                        ),
                      )
                    : IndexedStack(
                        index: _tab,
                        children: [
                          _circlePage(d),
                          LedgerScreen(data: d, onRefresh: _refresh),
                          MembersScreen(
                              data: d, onTap: _openMember, onRefresh: _refresh),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF08131A),
        indicatorColor: Palette.emerald.withOpacity(0.18),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.blur_circular), label: 'Circle'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: d != null && !d.integrity.valid,
              label: const Text('!'),
              child: const Icon(Icons.link),
            ),
            label: 'Ledger',
          ),
          const NavigationDestination(
              icon: Icon(Icons.groups), label: 'Members'),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (r) => emeraldGradient.createShader(r),
                  child: const Text('MUKANDOCHAIN',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Colors.white,
                      )),
                ),
                Text((_d?.groupName ?? 'SAVINGS CIRCLE').toUpperCase(),
                    style: const TextStyle(
                        color: Palette.dim, fontSize: 10, letterSpacing: 3)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'How it works',
            onPressed: _howItWorks,
            icon: const Icon(Icons.help_outline, color: Palette.dim),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.science_outlined, color: Palette.cyan),
            tooltip: 'Demo controls',
            color: const Color(0xFF0E2530),
            onSelected: (v) async {
              switch (v) {
                case 'fill':
                  await _call('/api/demo/fill', ok: 'Everyone has paid');
                  break;
                case 'tamper':
                  if (await _call('/api/demo/tamper',
                      ok: 'A record was secretly changed')) {
                    if (mounted) setState(() => _tab = 1);
                  }
                  break;
                default:
                  await _call('/api/demo/reset', ok: 'Demo reset');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'fill', child: Text('Everyone pays')),
              PopupMenuItem(
                  value: 'tamper', child: Text('Tamper with a record')),
              PopupMenuItem(value: 'reset', child: Text('Reset demo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Palette.dim, fontSize: 11)),
        ],
      );

  Widget _circlePage(SavingsCircle d) {
    final ok = d.integrity.valid;
    Widget bottom;
    if (d.roundComplete) {
      bottom = const GlassCard(
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Palette.gold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Round complete. Everyone has received their payout.',
                style: TextStyle(color: Palette.text),
              ),
            ),
          ],
        ),
      );
    } else if (d.canPayout) {
      bottom = GlowButton(
        label: 'RELEASE ${money(d.pot)} TO ${d.recipientName?.toUpperCase()}',
        icon: Icons.payments_rounded,
        gradient: goldGradient,
        glow: Palette.gold,
        onTap: () => _payout(d),
      );
    } else {
      bottom = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app, color: Palette.dim, size: 18),
          const SizedBox(width: 8),
          Text(
            'Tap a member to record their ${money(d.contribution)} payment',
            style: const TextStyle(color: Palette.dim, fontSize: 13),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _statusChip(
                ok ? 'Ledger verified' : 'Tampering detected',
                ok ? Icons.verified_user : Icons.gpp_bad,
                ok ? Palette.emerald : Palette.red,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 8),
              _statusChip(
                d.roundComplete
                    ? 'Round complete'
                    : 'Cycle ${d.cycle} of ${d.members.length}',
                Icons.autorenew,
                Palette.cyan,
              ),
            ],
          ),
          Expanded(
            child: CircleView(
              data: d,
              selectedId: _selectedId,
              onTap: _openMember,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Palette.emerald, 'Paid'),
              const SizedBox(width: 16),
              _legendDot(Palette.pending, 'Pending'),
              const SizedBox(width: 16),
              _legendDot(Palette.gold, 'Receives pot'),
            ],
          ),
          const SizedBox(height: 14),
          bottom,
        ],
      ),
    );
  }
}
