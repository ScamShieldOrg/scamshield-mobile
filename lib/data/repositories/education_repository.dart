import '../models/education_hub.dart';
import '../services/education_service.dart';

class EducationRepository {
  const EducationRepository();

  Future<EducationHub> loadHub({String? categoryCode}) async =>
      EducationHub.fromJson(
        await const EducationService().fetchHub(categoryCode: categoryCode),
      );
}
