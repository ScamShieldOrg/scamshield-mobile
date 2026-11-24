import '../home/scam_check_validation.dart';

enum DisputeIndicatorType {
  phone('Số điện thoại', '091.234.8899'),
  bankAccount('STK Ngân hàng', 'Ví dụ: 19036888999012'),
  url('Website / Link', 'Ví dụ: https://domain.vn'),
  brandname('Brandname', 'Ví dụ: TANPHAT_CSKH');

  const DisputeIndicatorType(this.label, this.hint);

  final String label;
  final String hint;
}

enum DisputeLegalRelationship {
  legalRepresentative('Đại diện pháp lý doanh nghiệp'),
  owner('Chủ sở hữu cá nhân / chính chủ'),
  authorizedRepresentative('Người được ủy quyền hợp pháp');

  const DisputeLegalRelationship(this.label);

  final String label;
}

class DisputeAttachmentItem {
  const DisputeAttachmentItem({
    required this.id,
    required this.fileName,
    required this.sizeLabel,
    required this.note,
  });

  final String id;
  final String fileName;
  final String sizeLabel;
  final String note;
}

const int maxDisputeReasonLength = 1000;
const int maxDisputeAttachmentCount = 10;

String? validateDisputeIndicatorValue(
  DisputeIndicatorType type,
  String? value,
) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) {
    return 'Vui lòng nhập chỉ số bị gắn nhầm.';
  }
  if (input.length > 255) {
    return 'Chỉ số cần khiếu nại tối đa 255 ký tự.';
  }

  return switch (type) {
    DisputeIndicatorType.phone when !isScamCheckPhone(input) =>
      'Nhập số điện thoại hoặc đầu số hợp lệ.',
    DisputeIndicatorType.bankAccount
        when !RegExp(r'^[A-Za-z0-9\s.-]{6,34}$').hasMatch(input) =>
      'Nhập số tài khoản ngân hàng hợp lệ (từ 6 đến 34 ký tự).',
    DisputeIndicatorType.url when parseScamCheckLink(input) == null =>
      'Nhập địa chỉ website hợp lệ, ví dụ domain.vn.',
    DisputeIndicatorType.brandname when input.length < 2 =>
      'Tên Brandname phải có ít nhất 2 ký tự.',
    _ => null,
  };
}

String? validateDisputeReason(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) {
    return 'Vui lòng nhập lý do khiếu nại và giải trình.';
  }
  if (input.length < 20) {
    return 'Giải trình cần tối thiểu 20 ký tự để phục vụ thẩm định.';
  }
  if (input.length > maxDisputeReasonLength) {
    return 'Lý do khiếu nại tối đa $maxDisputeReasonLength ký tự.';
  }
  return null;
}

String? validateDisputeAttachments(List<DisputeAttachmentItem> attachments) {
  if (attachments.isEmpty) {
    return 'Vui lòng đính kèm ít nhất 1 tài liệu xác minh chính chủ.';
  }
  if (attachments.length > maxDisputeAttachmentCount) {
    return 'Mỗi hồ sơ chỉ được đính kèm tối đa $maxDisputeAttachmentCount tệp.';
  }
  return null;
}

String? validateDisputeAgreement(bool agreed) {
  return agreed
      ? null
      : 'Bạn cần xác nhận cam đoan thông tin trước khi gửi đơn.';
}
