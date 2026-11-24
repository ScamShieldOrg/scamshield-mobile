import '../../ui/dispute/submit_dispute_validation.dart';
import '../models/dispute_models.dart';
import '../services/dispute_api_service.dart';

class DisputeRepository {
  DisputeRepository({DisputeApiService? apiService})
    : _apiService = apiService ?? DisputeApiService();

  final DisputeApiService _apiService;

  Future<DisputeSubmissionResult> submitDispute({
    required String accessToken,
    required DisputeIndicatorType indicatorType,
    required String indicatorValue,
    required DisputeLegalRelationship legalRelationship,
    required String reason,
    required bool agreeTerms,
    required List<DisputeAttachmentItem> attachments,
  }) {
    return _apiService.submitDispute(
      accessToken: accessToken,
      indicatorType: indicatorType,
      indicatorValue: indicatorValue,
      legalRelationship: legalRelationship,
      reason: reason,
      agreeTerms: agreeTerms,
      attachments: attachments,
    );
  }

  Future<DisputePageResult> fetchMyDisputes({
    required String accessToken,
    DisputeFilterTab filter = DisputeFilterTab.all,
    int page = 0,
    int size = 20,
  }) {
    return _apiService.getMyDisputes(
      accessToken: accessToken,
      statuses: filter.apiStatuses,
      page: page,
      size: size,
    );
  }

  Future<DisputeSummary> fetchMySummary({required String accessToken}) {
    return _apiService.getMySummary(accessToken: accessToken);
  }
}
