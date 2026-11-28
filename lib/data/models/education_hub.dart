typedef EducationCategory = ({String code, String name});

class EducationHub {
  const EducationHub({
    required this.categories,
    required this.scenarios,
    required this.totalScenarios,
  });

  factory EducationHub.fromJson(Map<String, dynamic> json) {
    final filters = json['filters'] as Map<String, dynamic>;
    final categories = filters['categories'] as List<dynamic>;
    final scenarios = json['scenarios'] as List<dynamic>;
    return EducationHub(
      categories: [
        for (final category in categories.cast<Map<String, dynamic>>())
          (code: category['code'] as String, name: category['name'] as String),
      ],
      scenarios: [
        for (final scenario in scenarios.cast<Map<String, dynamic>>())
          EducationScenario.fromJson(scenario),
      ],
      totalScenarios: json['totalScenarios'] as int,
    );
  }

  final List<EducationCategory> categories;
  final List<EducationScenario> scenarios;
  final int totalScenarios;
}

class EducationScenario {
  const EducationScenario({
    required this.id,
    required this.title,
    required this.summary,
    required this.tag,
    required this.badge,
    required this.example,
    required this.recognitionSigns,
    required this.goal,
    required this.actions,
    required this.tips,
  });

  factory EducationScenario.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final content = json['structuredContent'] as Map<String, dynamic>?;
    final example = content?['example'] as Map<String, dynamic>?;
    return EducationScenario(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: _text(json['summary']),
      tag: _text(json['tag']) ?? _text(category?['name']),
      badge: _text(json['badgeLabel']),
      example: example == null ? null : EducationExample.fromJson(example),
      recognitionSigns: _strings(content?['recognitionSigns']),
      goal: _text(content?['scammerGoal']),
      actions: _strings(content?['recommendedActions']),
      tips: _strings(content?['tips']),
    );
  }

  final int id;
  final String title;
  final String? summary;
  final String? tag;
  final String? badge;
  final EducationExample? example;
  final List<String> recognitionSigns;
  final String? goal;
  final List<String> actions;
  final List<String> tips;
}

class EducationExample {
  const EducationExample({
    required this.channel,
    required this.sender,
    required this.time,
    required this.message,
    required this.highlight,
  });

  factory EducationExample.fromJson(Map<String, dynamic> json) =>
      EducationExample(
        channel: _text(json['channelType']),
        sender: _text(json['senderName']),
        time: _text(json['displayTime']),
        message: _text(json['message']),
        highlight: _text(json['highlightedText']),
      );

  final String? channel;
  final String? sender;
  final String? time;
  final String? message;
  final String? highlight;
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

List<String> _strings(Object? value) =>
    value is List ? [for (final item in value) ?_text(item)] : const [];
