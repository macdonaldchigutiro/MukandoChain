import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

Future<void> showMemberSheet({
  required BuildContext context,
  required Member member,
  required SavingsCircle circle,
  required VoidCallback onRecord,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MemberSheet(
      member: member,
      circle: circle,
      onRecord: () {
        Navigator.pop(ctx);
        onRecord();
      },
    ),
  );
}

class _MemberSheet extends StatelessWidget {
  final Member member;
  final SavingsCircle circle;
  final VoidCallback onRecord;

  const _MemberSheet({
    required this.member,
    required this.circle,
    required this.onRecord,
  });

  Widget _tile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Palette.dim, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecipient = member.id == circle.recipientId;
    final color = member.paid ? Palette.emerald : Palette.dim;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1820),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Palette.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Palette.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.node,
                  border: Border.all(
                      color: isRecipient ? Palette.gold : color, width: 2.5),
                ),
                child: Text(member.initial,
                    style: TextStyle(
                        color: isRecipient ? Palette.gold : color,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(
                            color: Palette.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text(
                      member.paid
                          ? 'Paid for cycle ${circle.cycle}'
                          : 'Has not paid yet',
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRecipient) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Palette.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Palette.gold.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Palette.gold),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Receives the pot this cycle',
                        style: TextStyle(color: Palette.gold)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _tile('TOTAL PAID', money(member.totalPaid), Palette.text),
              const SizedBox(width: 10),
              _tile(
                'PAYOUT',
                member.receivedCycle == null
                    ? 'Not yet'
                    : 'Cycle ${member.receivedCycle}',
                member.receivedCycle == null ? Palette.dim : Palette.gold,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (circle.roundComplete)
            const Text('This round is complete.',
                style: TextStyle(color: Palette.dim))
          else if (member.paid)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Palette.emerald, size: 20),
                SizedBox(width: 8),
                Text('Payment recorded on the ledger',
                    style: TextStyle(color: Palette.emerald)),
              ],
            )
          else
            GlowButton(
              label: 'RECORD ${money(circle.contribution)} PAYMENT',
              icon: Icons.add_card,
              onTap: onRecord,
            ),
        ],
      ),
    );
  }
}
