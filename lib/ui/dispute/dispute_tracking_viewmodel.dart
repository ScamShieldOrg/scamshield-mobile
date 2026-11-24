import 'package:flutter/foundation.dart';

import '../../data/models/api_exception.dart';
import '../../data/models/dispute_models.dart';
import '../../data/repositories/dispute_repository.dart';

class DisputeTrackingViewModel extends ChangeNotifier {
  DisputeTrackingViewModel({required DisputeRepository disputeRepository})
    : _disputeRepository = disputeRepository;

  final DisputeRepository _disputeRepository;

  DisputeFilterTab _activeFilter = DisputeFilterTab.all;
  DisputeSummary? _summary;
  List<DisputeRecord> _items = const [];
  int _currentPage = 0;
  bool _hasNext = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _disposed = false;
  int _requestGeneration = 0;

  DisputeFilterTab get activeFilter => _activeFilter;
  DisputeSummary? get summary => _summary;
  List<DisputeRecord> get items => _items;
  bool get hasNext => _hasNext;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll({required String accessToken}) async {
    final generation = ++_requestGeneration;
    _isLoadingMore = false;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<Object>([
        _disputeRepository.fetchMySummary(accessToken: accessToken),
        _disputeRepository.fetchMyDisputes(
          accessToken: accessToken,
          filter: _activeFilter,
          page: 0,
        ),
      ]);
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      final summary = results[0] as DisputeSummary;
      final page = results[1] as DisputePageResult;
      _summary = summary;
      _items = page.items;
      _currentPage = page.currentPage;
      _hasNext = page.hasNext;
    } on ApiException catch (error) {
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _errorMessage = error.message;
    } catch (_) {
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _errorMessage = 'Không thể tải danh sách hồ sơ khiếu nại.';
    } finally {
      if (!_disposed && generation == _requestGeneration) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  Future<void> selectFilter({
    required DisputeFilterTab filter,
    required String accessToken,
  }) async {
    if (_activeFilter == filter && _items.isNotEmpty && _errorMessage == null) {
      return;
    }
    _activeFilter = filter;
    final generation = ++_requestGeneration;
    _items = const [];
    _currentPage = 0;
    _hasNext = false;
    _isLoadingMore = false;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final page = await _disputeRepository.fetchMyDisputes(
        accessToken: accessToken,
        filter: filter,
        page: 0,
      );
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _items = page.items;
      _currentPage = page.currentPage;
      _hasNext = page.hasNext;
    } on ApiException catch (error) {
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _errorMessage = error.message;
    } catch (_) {
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _errorMessage = 'Không thể tải danh sách hồ sơ khiếu nại.';
    } finally {
      if (!_disposed && generation == _requestGeneration) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  Future<void> loadMore({required String accessToken}) async {
    if (_isLoading || _isLoadingMore || !_hasNext) {
      return;
    }
    final generation = _requestGeneration;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final page = await _disputeRepository.fetchMyDisputes(
        accessToken: accessToken,
        filter: _activeFilter,
        page: _currentPage + 1,
      );
      if (_disposed || generation != _requestGeneration) {
        return;
      }
      _items = [..._items, ...page.items];
      _currentPage = page.currentPage;
      _hasNext = page.hasNext;
    } catch (_) {
      // Keep already loaded items if pagination fetch fails.
    } finally {
      if (!_disposed && generation == _requestGeneration) {
        _isLoadingMore = false;
        _safeNotify();
      }
    }
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
