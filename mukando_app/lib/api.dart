import 'dart:convert';

import 'package:http/http.dart' as http;

// Where the MukandoChain backend runs.
// Web / desktop      -> http://localhost:8001
// Android emulator   -> http://10.0.2.2:8001
// Real phone, Wi-Fi  -> http://YOUR-PC-IP:8001
const String baseUrl = 'http://localhost:8001';

int _i(dynamic v) => (v as num).toInt();

class Member {
  final String id, name;
  final bool paid;
  final int? receivedCycle;
  final int totalPaid;

  Member({
    required this.id,
    required this.name,
    required this.paid,
    required this.receivedCycle,
    required this.totalPaid,
  });

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String,
        paid: j['paid'] as bool,
        receivedCycle:
            j['received_cycle'] == null ? null : _i(j['received_cycle']),
        totalPaid: _i(j['total_paid']),
      );
}

class Block {
  final int index;
  final double ts;
  final String type, prev, hash;
  final Map<String, dynamic> data;

  Block({
    required this.index,
    required this.ts,
    required this.type,
    required this.prev,
    required this.hash,
    required this.data,
  });

  String get shortHash => hash.substring(0, 8);
  String get shortPrev => prev.substring(0, 8);

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        index: _i(j['index']),
        ts: (j['ts'] as num).toDouble(),
        type: j['type'] as String,
        prev: j['prev'] as String,
        hash: j['hash'] as String,
        data: Map<String, dynamic>.from(j['data'] as Map),
      );
}

class Integrity {
  final bool valid;
  final int checked;
  final int? badIndex;
  final String head;

  Integrity(this.valid, this.checked, this.badIndex, this.head);

  factory Integrity.fromJson(Map<String, dynamic> j) => Integrity(
        j['valid'] as bool,
        _i(j['checked']),
        j['bad_index'] == null ? null : _i(j['bad_index']),
        j['head'] as String,
      );
}

class SavingsCircle {
  final String groupName;
  final int contribution, cycle, pot, target;
  final bool roundComplete, canPayout;
  final String? recipientId, recipientName;
  final List<Member> members;
  final List<Block> ledger;
  final Integrity integrity;

  SavingsCircle({
    required this.groupName,
    required this.contribution,
    required this.cycle,
    required this.pot,
    required this.target,
    required this.roundComplete,
    required this.canPayout,
    required this.recipientId,
    required this.recipientName,
    required this.members,
    required this.ledger,
    required this.integrity,
  });

  int get paidCount => members.where((m) => m.paid).length;

  factory SavingsCircle.fromJson(Map<String, dynamic> j) {
    final g = j['group'] as Map<String, dynamic>;
    final rec = j['recipient'] as Map<String, dynamic>?;
    return SavingsCircle(
      groupName: g['name'] as String,
      contribution: _i(g['contribution']),
      cycle: _i(j['cycle']),
      pot: _i(j['pot']),
      target: _i(j['target']),
      roundComplete: j['round_complete'] as bool,
      canPayout: j['can_payout'] as bool,
      recipientId: rec?['id'] as String?,
      recipientName: rec?['name'] as String?,
      members: (j['members'] as List)
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList(),
      ledger: (j['ledger'] as List)
          .map((e) => Block.fromJson(e as Map<String, dynamic>))
          .toList(),
      integrity:
          Integrity.fromJson(j['integrity'] as Map<String, dynamic>),
    );
  }
}

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
}

class Api {
  static Future<SavingsCircle> fetch() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/state'))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) throw ApiError('Server error');
    return SavingsCircle.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> post(String path) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode >= 400) {
      String detail = 'Something went wrong.';
      try {
        detail = jsonDecode(res.body)['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiError(detail);
    }
  }
}

String money(int v) => '\$$v';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDate(double ts) {
  final d = DateTime.fromMillisecondsSinceEpoch((ts * 1000).round());
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_months[d.month - 1]} ${d.year}, $hh:$mm';
}

String blockSummary(Block b) {
  switch (b.type) {
    case 'GROUP_CREATED':
      return 'Circle created: ${b.data['name']}';
    case 'CONTRIBUTION':
      return '${b.data['member_name']} paid ${money(_i(b.data['amount']))}';
    case 'PAYOUT':
      return 'Payout ${money(_i(b.data['amount']))} to ${b.data['member_name']}';
    default:
      return b.type;
  }
}
