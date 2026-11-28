import '../models/resource_entry.dart';
import '../services/resource_service.dart';

class ResourceRepository {
  const ResourceRepository();

  static const _service = ResourceService();

  Future<List<String>> loadPublicEvidence(int id) =>
      _service.fetchPublicEvidence(id);

  Future<ResourcePage> load({
    required ResourceList list,
    int page = 0,
    String keyword = '',
    ResourceType type = ResourceType.all,
    ResourceSort sort = ResourceSort.newest,
  }) async {
    final query = keyword.trim();
    final data = await _service.fetch(list.path, {
      'page': '$page',
      'size': '10',
      if (query.isNotEmpty) 'keyword': query,
      if (list == ResourceList.warnings && type.code != null)
        'resourceType': type.code!,
      if (list == ResourceList.verified) 'sortBy': sort.name,
    });
    final entries = (data['data'] as List<dynamic>)
        .map(
          (item) => ResourceEntry.fromJson(item as Map<String, dynamic>, list),
        )
        .toList();
    // The warning endpoint has no sort parameter. The web sorts each page.
    if (list == ResourceList.warnings) {
      switch (sort) {
        case ResourceSort.newest:
          break;
        case ResourceSort.name:
          entries.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        case ResourceSort.reports:
          entries.sort((a, b) => b.warnings.compareTo(a.warnings));
      }
    }
    return (
      entries: entries,
      total: (data['totalItems'] as num).toInt(),
      hasNext: data['hasNext'] == true,
    );
  }
}
