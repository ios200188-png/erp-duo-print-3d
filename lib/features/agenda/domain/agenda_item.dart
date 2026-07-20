enum AgendaItemType { delivery, receivable, payable, maintenance, stock }

class AgendaItem {
  const AgendaItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isUrgent,
    this.referenceId,
  });

  final AgendaItemType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final bool isUrgent;
  final int? referenceId;
}
