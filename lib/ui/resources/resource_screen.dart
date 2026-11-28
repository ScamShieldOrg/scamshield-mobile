import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../data/models/resource_entry.dart';
import '../../data/repositories/resource_repository.dart';
import '../auth/login_screen.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'resource_card.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key, this.onSignOut, this.onLightModeChanged});

  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  static const _guestEntryLimit = 3;
  static const _repository = ResourceRepository();
  final _search = TextEditingController();
  final _resultsKey = GlobalKey();
  ResourceList _list = ResourceList.warnings;
  ResourceType _type = ResourceType.all;
  ResourceSort _sort = ResourceSort.newest;
  ResourcePage? _result;
  Timer? _debounce;
  int _page = 0;
  int _request = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 0}) async {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _page = page;
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _repository.load(
        list: _list,
        page: page,
        keyword: _search.text,
        type: _type,
        sort: _sort,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _request++;
    setState(() {
      _loading = true;
      _failed = false;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  void _changePage(int page) {
    final target = _resultsKey.currentContext;
    if (target != null) {
      unawaited(Scrollable.ensureVisible(target));
    }
    unawaited(_load(page: page));
  }

  void _showSignInPrompt() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded),
        title: const Text('Xem thêm'),
        content: const Text('Đăng nhập để xem toàn bộ danh sách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              navigator.push<bool>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final warnings = _list == ResourceList.warnings;
    final result = _result;
    final authState = context.watch<AuthState?>();
    final isGuest = !(authState?.isAuthenticated ?? (widget.onSignOut != null));

    return Scaffold(
      appBar: const ScamShieldHeader(pageTitle: 'Tra cứu tài nguyên'),
      endDrawer: GuestMenu(
        onSignOut: widget.onSignOut,
        onLightModeChanged: widget.onLightModeChanged,
        isResourcesOpen: true,
      ),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.menu,
        onSignOut: widget.onSignOut,
        onLightModeChanged: widget.onLightModeChanged,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _load(page: _page),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<ResourceList>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: colors.primary,
                          selectedForegroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        selected: {_list},
                        onSelectionChanged: (selection) {
                          _list = selection.single;
                          if (_list == ResourceList.verified &&
                              _sort == ResourceSort.reports) {
                            _sort = ResourceSort.newest;
                          }
                          _load();
                        },
                        segments: [
                          for (final list in ResourceList.values)
                            ButtonSegment(
                              value: list,
                              label: Text(
                                list.label,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        warnings
                            ? 'Tra cứu số điện thoại, tên miền và tài khoản ngân hàng đã được ghi nhận cảnh báo.'
                            : 'Tra cứu thông tin liên hệ của các đơn vị đã được xác minh.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _load(),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Tìm kiếm',
                          hintText: warnings
                              ? 'Số điện thoại, tên miền, số tài khoản'
                              : 'Tên đơn vị, hotline, tên miền',
                          filled: true,
                          fillColor: colors.surfaceContainerLow,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colors.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Xóa tìm kiếm',
                                  onPressed: () {
                                    _search.clear();
                                    _load();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      if (warnings) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Lọc theo loại tài nguyên',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final type in ResourceType.values)
                              if (type != ResourceType.sms)
                                ChoiceChip(
                                  label: Text(type.label),
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: type == _type
                                            ? colors.onPrimary
                                            : colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  showCheckmark: true,
                                  checkmarkColor: colors.onPrimary,
                                  selectedColor: colors.primary,
                                  backgroundColor: colors.surface,
                                  side: BorderSide(
                                    color: type == _type
                                        ? colors.primary
                                        : colors.outlineVariant,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  selected: type == _type,
                                  onSelected: (selected) {
                                    if (!selected) return;
                                    _type = type;
                                    _load();
                                  },
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                key: _resultsKey,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    !_loading && !_failed && result != null
                        ? '${result.total} kết quả'
                        : 'Kết quả tra cứu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PopupMenuButton<ResourceSort>(
                    tooltip: 'Sắp xếp kết quả',
                    initialValue: _sort,
                    onSelected: (sort) {
                      if (sort == _sort) return;
                      _sort = sort;
                      _load();
                    },
                    itemBuilder: (_) => [
                      for (final sort in ResourceSort.values)
                        if (warnings || sort != ResourceSort.reports)
                          CheckedPopupMenuItem(
                            value: sort,
                            checked: sort == _sort,
                            child: Text(sort.label),
                          ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(_sort.label, style: theme.textTheme.labelLarge),
                          const Icon(Icons.arrow_drop_down_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading)
                const LinearProgressIndicator(
                  semanticsLabel: 'Đang tải kết quả',
                )
              else if (_failed) ...[
                const Text('Không tải được kết quả. Vui lòng thử lại.'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => _load(page: _page),
                    child: const Text('Thử lại'),
                  ),
                ),
              ] else if (result == null || result.entries.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Không tìm thấy kết quả phù hợp.'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                for (final entry
                    in isGuest
                        ? result.entries.take(_guestEntryLimit)
                        : result.entries)
                  ResourceCard(entry: entry, list: _list),
                if (isGuest) ...[
                  if (result.total > _guestEntryLimit ||
                      result.entries.length > _guestEntryLimit ||
                      result.hasNext) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showSignInPrompt,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      label: const Text('Xem thêm'),
                    ),
                  ],
                ] else if (_page > 0 || result.hasNext)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Trang trước',
                        onPressed: _page > 0
                            ? () => _changePage(_page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text('Trang ${_page + 1}'),
                      IconButton(
                        tooltip: 'Trang sau',
                        onPressed: result.hasNext
                            ? () => _changePage(_page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
