import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cash_transaction.dart';
import 'cash_repository.dart';

final cashServiceProvider = Provider<CashService>((ref) {
  return CashService(ref.watch(cashRepositoryProvider));
});

class CashService {
  CashService(this._repository);

  final CashRepository _repository;

  Future<CashFlowData> load({
    required DateTime start,
    required DateTime end,
  }) async {
    await _repository.synchronizePaidEntries();

    final results = await Future.wait<Object>([
      _repository.findByPeriod(start: start, end: end),
      _repository.summaryByPeriod(start: start, end: end),
    ]);

    final transactions = results[0] as List<CashTransaction>;
    final summary = results[1] as CashFlowSummary;

    var runningBalance = summary.openingBalance;
    final chronological = transactions.reversed.toList(growable: false);
    final balanceById = <int, double>{};

    for (final transaction in chronological) {
      runningBalance += transaction.signedAmount;
      balanceById[transaction.id] = runningBalance;
    }

    return CashFlowData(
      transactions: transactions,
      summary: summary,
      balanceByTransactionId: balanceById,
    );
  }
}

class CashFlowData {
  const CashFlowData({
    required this.transactions,
    required this.summary,
    required this.balanceByTransactionId,
  });

  final List<CashTransaction> transactions;
  final CashFlowSummary summary;
  final Map<int, double> balanceByTransactionId;
}
