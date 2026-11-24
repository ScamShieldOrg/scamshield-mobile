class UserScamCheckQuota {
  const UserScamCheckQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    this.userId,
    this.fullName,
    this.rankName,
    this.resetsAt,
  });

  final int? userId;
  final String? fullName;
  final String? rankName;
  final int limit;
  final int used;
  final int remaining;
  final String? resetsAt;

  factory UserScamCheckQuota.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['userId'];
    final rawLimit = json['limit'];
    final rawUsed = json['used'];
    final rawRemaining = json['remaining'];

    final parsedLimit = rawLimit is num
        ? rawLimit.toInt()
        : int.tryParse('$rawLimit') ?? 0;
    final parsedUsed = rawUsed is num
        ? rawUsed.toInt()
        : int.tryParse('$rawUsed') ?? 0;
    final parsedRemaining = rawRemaining is num
        ? rawRemaining.toInt()
        : int.tryParse('$rawRemaining') ?? (parsedLimit - parsedUsed);

    return UserScamCheckQuota(
      userId: rawUserId is num ? rawUserId.toInt() : int.tryParse('$rawUserId'),
      fullName: (json['fullName'] as String?)?.trim(),
      rankName: (json['rankName'] as String?)?.trim(),
      limit: parsedLimit < 0 ? 0 : parsedLimit,
      used: parsedUsed < 0 ? 0 : parsedUsed,
      remaining: parsedRemaining < 0 ? 0 : parsedRemaining,
      resetsAt: (json['resetsAt'] as String?)?.trim(),
    );
  }
}
