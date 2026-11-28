import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/education_hub.dart';
import '../../data/repositories/education_repository.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'education_scenario_card.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key, this.onSignOut, this.onLightModeChanged});

  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  static const _repository = EducationRepository();
  EducationHub? _hub;
  String? _categoryCode;
  bool _loading = true;
  bool _failed = false;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_requestNumber;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final hub = await _repository.loadHub(categoryCode: _categoryCode);
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _hub = hub;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _selectCategory(String? code) {
    if (_categoryCode == code) return;
    _categoryCode = code;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hub = _hub;

    return Scaffold(
      appBar: const ScamShieldHeader(pageTitle: 'Cẩm nang an toàn'),
      endDrawer: GuestMenu(
        onSignOut: widget.onSignOut,
        onLightModeChanged: widget.onLightModeChanged,
        isEducationOpen: true,
      ),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.menu,
        onSignOut: widget.onSignOut,
        onLightModeChanged: widget.onLightModeChanged,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _EducationHero(),
              if (hub != null && hub.categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _categoryCode == null,
                      onSelected: (_) => _selectCategory(null),
                    ),
                    for (final category in hub.categories)
                      ChoiceChip(
                        label: Text(category.name),
                        selected: _categoryCode == category.code,
                        onSelected: (_) => _selectCategory(category.code),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'Thư viện thủ đoạn lừa đảo',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Đang tải tình huống',
                    ),
                  ),
                )
              else if (_failed)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Chưa tải được cẩm nang an toàn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.error),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (hub != null)
                if (hub.scenarios.isEmpty)
                  Text(
                    'Chưa có tình huống cho chủ đề này.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  )
                else ...[
                  if (hub.totalScenarios > hub.scenarios.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${hub.scenarios.length} tình huống mới nhất',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final scenario in hub.scenarios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EducationScenarioCard(
                        key: PageStorageKey(scenario.id),
                        scenario: scenario,
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EducationHero extends StatelessWidget {
  const _EducationHero();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF194984)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(9),
              child: Icon(Icons.menu_book_outlined, color: AppTheme.shieldBlue),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Học viện phòng chống\nlừa đảo',
            style: text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhận diện thủ đoạn và biết cách bảo vệ mình qua từng tình huống.',
            style: text.bodyMedium?.copyWith(
              color: const Color(0xFFDAE7FC),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
