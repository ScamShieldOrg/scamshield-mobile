import '../models/user_scam_check_quota.dart';
import '../services/user_quota_api_service.dart';

class UserQuotaRepository {
  UserQuotaRepository({UserQuotaApiService? apiService})
    : _apiService = apiService ?? UserQuotaApiService();

  final UserQuotaApiService _apiService;

  Future<UserScamCheckQuota> fetchMyQuota({required String accessToken}) {
    return _apiService.getMyQuota(accessToken: accessToken);
  }
}
