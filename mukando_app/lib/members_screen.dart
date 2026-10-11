import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

class MembersScreen extends StatelessWidget {
  final SavingsCircle data;
  final ValueChanged<Member> onTap;
  final Future<void> Function() onRefresh;

  const MembersScreen({
    super.key,
    required this.data,
    required this.onTap,
    required this.onRefresh,
  });

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Palette.emerald,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: data.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final m = data.members[i];
          final isRecipient = m.id == data.recipientId;
          final color = isRecipient
              ? Palette.gold
              : (m.paid ? Palette.emerald : Palette.pending);
          return GestureDetector(
            onTap: () => onTap(m),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.node,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Text(m.initial,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: const TextStyle(
                                color: Palette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (!data.roundComplete)
                              m.paid
                                  ? _chip('PAID', Palette.emerald)
                                  : _chip('PENDING', Palette.dim),
                            if (isRecipient) _chip('RECEIVES NEXT', Palette.gold),
                            if (m.receivedCycle != null)
                              _chip('GOT PAYOUT C${m.receivedCycle}',
                                  Palette.gold),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(m.totalPaid),
                          style: const TextStyle(
                              color: Palette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const Text('paid in',
                          style: TextStyle(color: Palette.dim, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
