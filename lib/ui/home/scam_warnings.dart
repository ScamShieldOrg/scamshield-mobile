import 'package:flutter/material.dart';

class ScamWarnings extends StatelessWidget {
  const ScamWarnings({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFB42318)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cảnh báo lừa đảo',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tình huống minh họa',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const _WarningCard(
          category: 'Mạo danh cơ quan chức năng',
          title: 'Giả danh cán bộ thuế hoặc công an yêu cầu kích hoạt VNeID',
          description:
              'Kẻ giả mạo gửi đường dẫn qua Zalo và yêu cầu cài ứng dụng ngoài kho chính thức.',
          severity: 'Cực kỳ nguy hiểm',
          color: Color(0xFFB42318),
        ),
        const _WarningCard(
          category: 'Lừa đảo đầu tư tài chính',
          title: 'Sàn đầu tư cam kết lợi nhuận 30% mỗi ngày',
          description:
              'Kẻ lừa đảo yêu cầu nạp tiền qua ví trung gian rồi đòi thêm phí để mở khóa rút tiền.',
          severity: 'Rất rủi ro',
          color: Color(0xFF9A3412),
        ),
        const _WarningCard(
          category: 'Mạo danh quà tặng trúng thưởng',
          title: 'Tin nhắn giả mạo thông báo trúng quà Shopee hoặc Tiki',
          description:
              'Tin nhắn dẫn tới trang yêu cầu nhập thông tin thẻ và mã OTP để nhận quà.',
          severity: 'Cực kỳ nguy hiểm',
          color: Color(0xFFB42318),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.color,
  });

  final String category;
  final String title;
  final String description;
  final String severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            category,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(description),
          const SizedBox(height: 8),
          Text(
            severity,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.error
                  : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
