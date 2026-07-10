// lib/shared/models/report_comment_model.dart

class ReportComment {
  final String initials;
  final String name;
  final String time;
  final String text;
  final DateTime createdAt;

  const ReportComment({
    required this.initials,
    required this.name,
    required this.time,
    required this.text,
    required this.createdAt,
  });
}
