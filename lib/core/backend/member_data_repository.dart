import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only member contract. These methods are deliberately not called by the
/// app shell until an approved non-production account is available for testing.
abstract interface class MemberDataRepository {
  Future<MemberProfile?> myProfile();
  Future<MemberMembership?> myMembership();
  Future<List<MemberStartup>> myStartups();
  Future<MemberNotificationInbox> myNotificationInbox();
}

class MemberProfile {
  const MemberProfile({
    required this.userId,
    required this.displayName,
    required this.aboutMe,
    required this.city,
    required this.profileCompletion,
  });

  final String userId;
  final String displayName;
  final String aboutMe;
  final String? city;
  final int profileCompletion;

  factory MemberProfile.fromJson(Map<String, dynamic> json) => MemberProfile(
    userId: _text(json['id']),
    displayName:
        _nullableText(json['display_name']) ??
        _nullableText(json['full_name']) ??
        '',
    aboutMe: _nullableText(json['about_me']) ?? '',
    city: _nullableText(json['city']),
    profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 0,
  );
}

class MemberMembership {
  const MemberMembership({
    required this.status,
    this.memberNumber,
    this.issuedAt,
    this.expiresAt,
  });

  final String status;
  final String? memberNumber;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  factory MemberMembership.fromJson(Map<String, dynamic> json) =>
      MemberMembership(
        status: _text(json['status']),
        memberNumber: _nullableText(json['member_number']),
        issuedAt: _date(json['issued_at']),
        expiresAt: _date(json['expires_at']),
      );
}

class MemberStartup {
  const MemberStartup({
    required this.id,
    required this.slug,
    required this.name,
    required this.industry,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String industry;
  final String status;
  final DateTime updatedAt;

  factory MemberStartup.fromJson(Map<String, dynamic> json) => MemberStartup(
    id: _text(json['id']),
    slug: _text(json['slug']),
    name: _text(json['name']),
    industry: _nullableText(json['industry']) ?? 'other',
    status: _text(json['status']),
    updatedAt:
        _date(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class MemberNotification {
  const MemberNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.actionPath,
    this.readAt,
  });

  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final String? actionPath;
  final DateTime? readAt;

  factory MemberNotification.fromJson(Map<String, dynamic> json) =>
      MemberNotification(
        id: _text(json['id']),
        title: _nullableText(json['title']) ?? 'CSC Circle update',
        message: _nullableText(json['message']) ?? '',
        createdAt: _date(json['delivered_at']) ?? _date(json['created_at']),
        actionPath: _nullableText(json['action_url']),
        readAt: _date(json['read_at']),
      );
}

class MemberNotificationInbox {
  const MemberNotificationInbox({
    required this.items,
    required this.unreadCount,
  });

  final List<MemberNotification> items;
  final int unreadCount;
}

class SupabaseMemberDataRepository implements MemberDataRepository {
  SupabaseMemberDataRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw const MemberAccessException();
    return user.id;
  }

  @override
  Future<MemberProfile?> myProfile() async {
    final row = await _client
        .from('profiles')
        .select('id,full_name,display_name,city,about_me,profile_completion')
        .eq('id', _userId)
        .maybeSingle();
    return row == null ? null : MemberProfile.fromJson(row);
  }

  @override
  Future<MemberMembership?> myMembership() async {
    final row = await _client
        .from('memberships')
        .select('status,member_number,issued_at,expires_at')
        .eq('user_id', _userId)
        .maybeSingle();
    return row == null ? null : MemberMembership.fromJson(row);
  }

  @override
  Future<List<MemberStartup>> myStartups() async {
    final rows = await _client
        .from('directory_startups')
        .select('id,slug,name,industry,status,updated_at')
        .eq('user_id', _userId)
        .order('updated_at', ascending: false)
        .range(0, 19);
    return rows
        .map((row) => MemberStartup.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<MemberNotificationInbox> myNotificationInbox() async {
    // Fail locally before invoking the authenticated, caller-scoped RPC.
    if (_client.auth.currentUser == null) throw const MemberAccessException();
    final json = await _client.rpc('csc_member_notification_inbox');
    if (json is! Map) throw const MemberAccessException();
    final map = Map<String, dynamic>.from(json);
    final items = (map['items'] as List<dynamic>? ?? const [])
        .map(
          (row) => MemberNotification.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
    return MemberNotificationInbox(
      items: items,
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MemberAccessException implements Exception {
  const MemberAccessException();
}

String _text(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  throw const MemberAccessException();
}

String? _nullableText(Object? value) => value is String ? value : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
