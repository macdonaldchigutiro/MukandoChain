import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'theme.dart';

class LedgerScreen extends StatefulWidget {
  final SavingsCircle data;
  final Future<void> Function() onRefresh;

  const LedgerScreen({super.key, required this.data, required this.onRefresh});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  bool _verifying = false;

  Future<void> _verify() async {
    setState(() => _verifying = true);
    HapticFeedback.lightImpact();
    await widget.onRefresh();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _verifying = false);
  }

  Widget _banner() {
    final i = widget.data.integrity;
    final ok = i.valid;
    final color = ok ? Palette.emerald : Palette.red;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.7)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(ok ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  color: color, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ok ? 'ALL RECORDS INTACT' : 'TAMPERING DETECTED',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      ok
                          ? '${i.checked} records checked. Nothing has been changed.'
                          : 'Record #${i.badIndex} does not match its fingerprint. Do not trust the balances until this is sorted out.',
                      style: const TextStyle(
                          color: Palette.dim, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_verifying) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                color: color,
                backgroundColor: Palette.glassBorder,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Checking every fingerprint…',
                style: TextStyle(color: Palette.dim, fontSize: 11)),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _verify,
                icon: Icon(Icons.radar, color: color, size: 18),
                label: Text('VERIFY NOW', style: TextStyle(color: color)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(Block b) {
    final bad = widget.data.integrity.badIndex == b.index;
    final isPayout = b.type == 'PAYOUT';
    final isGenesis = b.type == 'GROUP_CREATED';
    final color = bad
        ? Palette.red
        : (isPayout
            ? Palette.gold
            : (isGenesis ? Palette.cyan : Palette.emerald));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                        width: 2, color: Palette.emerald.withOpacity(0.25)),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 22),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.7), blurRadius: 8)
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _detail(b),
                child: GlassCard(
                  borderColor: bad ? Palette.red.withOpacity(0.8) : null,
                  tint: bad ? Palette.red.withOpacity(0.08) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(blockSummary(b),
                                style: TextStyle(
                                    color: isPayout || bad
                                        ? color
                                        : Palette.text,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (bad)
                            const Text('ALTERED',
                                style: TextStyle(
                                    color: Palette.red,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(fmtDate(b.ts),
                          style: const TextStyle(
                              color: Palette.dim, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        '#${b.index}  ${b.shortHash}   ←  ${b.shortPrev}',
                        style: const TextStyle(
                            color: Palette.dim,
                            fontSize: 10.5,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _detail(Block b) {
    final receipt = 'MukandoChain receipt\n'
        'Record #${b.index}\n'
        '${blockSummary(b)}\n'
        '${fmtDate(b.ts)}\n'
        'Fingerprint: ${b.hash}\n'
        'Previous: ${b.prev}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1820),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Palette.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECORD #${b.index}',
                style: const TextStyle(
                    color: Palette.cyan, letterSpacing: 3, fontSize: 12)),
            const SizedBox(height: 6),
            Text(blockSummary(b),
                style: const TextStyle(
                    color: Palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w700)),
            Text(fmtDate(b.ts),
                style: const TextStyle(color: Palette.dim, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('FINGERPRINT',
                style: TextStyle(
                    color: Palette.dim, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            SelectableText(b.hash,
                style: const TextStyle(
                    color: Palette.emerald,
                    fontFamily: 'monospace',
                    fontSize: 12)),
            const SizedBox(height: 12),
            const Text('LINKED TO PREVIOUS RECORD',
                style: TextStyle(
                    color: Palette.dim, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            SelectableText(b.prev,
                style: const TextStyle(
                    color: Palette.dim,
                    fontFamily: 'monospace',
                    fontSize: 12)),
            const SizedBox(height: 20),
            GlowButton(
              label: 'COPY RECEIPT',
              icon: Icons.copy_rounded,
              onTap: () {
                Clipboard.setData(ClipboardData(text: receipt));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Receipt copied'),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Palette.emerald,
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _banner(),
          for (final b in widget.data.ledger) _row(b),
        ],
      ),
    );
  }
}
