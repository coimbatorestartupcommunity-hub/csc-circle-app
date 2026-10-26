import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum PublicContentKind { events, updates, resources, opportunities }

sealed class PublicContentItem {
  const PublicContentItem({required this.id, required this.title});

  final String id;
  final String title;
  String get summary;
  String get category;
  DateTime? get date;
}

final class CscEvent extends PublicContentItem {
  const CscEvent({
    required super.id,
    required super.title,
    required this.description,
    required this.category,
    required this.startsAt,
    required this.endsAt,
    required this.location,
    this.venue,
    this.coverImage,
  });

  final String description;
  @override
  final String category;
  final DateTime startsAt;
  final DateTime endsAt;
  final String location;
  final String? venue;
  final String? coverImage;
  @override
  String get summary => description;
  @override
  DateTime get date => startsAt;

  factory CscEvent.fromJson(Map<String, dynamic> json) => CscEvent(
    id: _requiredText(json, 'id'),
    title: _requiredText(json, 'title'),
    description: _optionalText(json, 'description') ?? '',
    category: _optionalText(json, 'category') ?? 'Community event',
    startsAt: _requiredDate(json, 'starts_at'),
    endsAt: _requiredDate(json, 'ends_at'),
    location: _optionalText(json, 'location') ?? 'Location to be announced',
    venue: _optionalText(json, 'venue'),
    coverImage: _optionalText(json, 'cover_image'),
  );
}

final class CommunityUpdate extends PublicContentItem {
  const CommunityUpdate({
    required super.id,
    required super.title,
    required this.slug,
    required this.summary,
    required this.category,
    required this.featured,
    this.coverImagePath,
    this.coverImageAlt,
    this.publishedAt,
  });

  final String slug;
  @override
  final String summary;
  @override
  final String category;
  final bool featured;
  final String? coverImagePath;
  final String? coverImageAlt;
  final DateTime? publishedAt;
  @override
  DateTime? get date => publishedAt;

  factory CommunityUpdate.fromJson(Map<String, dynamic> json) =>
      CommunityUpdate(
        id: _requiredText(json, 'id'),
        title: _requiredText(json, 'title'),
        slug: _requiredText(json, 'slug'),
        summary: _optionalText(json, 'summary') ?? '',
        category: _optionalText(json, 'category') ?? 'Community update',
        featured: json['featured'] == true,
        coverImagePath: _optionalText(json, 'cover_image_path'),
        coverImageAlt: _optionalText(json, 'cover_image_alt'),
        publishedAt: _optionalDate(json, 'published_at'),
      );
}

final class CscResource extends PublicContentItem {
  const CscResource({
    required super.id,
    required super.title,
    required this.slug,
    required this.summary,
    required this.category,
    required this.resourceType,
    required this.tags,
    this.externalUrl,
    this.publishedAt,
  });

  final String slug;
  @override
  final String summary;
  @override
  final String category;
  final String resourceType;
  final List<String> tags;
  final String? externalUrl;
  final DateTime? publishedAt;
  @override
  DateTime? get date => publishedAt;

  factory CscResource.fromJson(Map<String, dynamic> json) => CscResource(
    id: _requiredText(json, 'id'),
    title: _requiredText(json, 'title'),
    slug: _requiredText(json, 'slug'),
    summary: _optionalText(json, 'summary') ?? '',
    category: _optionalText(json, 'category') ?? 'Resource',
    resourceType: _optionalText(json, 'resource_type') ?? 'article',
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    externalUrl: _optionalText(json, 'external_url'),
    publishedAt: _optionalDate(json, 'published_at'),
  );
}

final class CscOpportunity extends PublicContentItem {
  const CscOpportunity({
    required super.id,
    required super.title,
    required this.summary,
    required this.category,
    this.organization,
    this.deadline,
    this.startsOn,
    this.applicationUrl,
  });

  @override
  final String summary;
  @override
  final String category;
  final String? organization;
  final DateTime? deadline;
  final DateTime? startsOn;
  final String? applicationUrl;
  @override
  DateTime? get date => deadline ?? startsOn;

  factory CscOpportunity.fromJson(Map<String, dynamic> json) => CscOpportunity(
    id: _requiredText(json, 'id'),
    title: _requiredText(json, 'title'),
    summary: _optionalText(json, 'summary') ?? '',
    category: _optionalText(json, 'category') ?? 'Opportunity',
    organization: _optionalText(json, 'organization'),
    deadline: _optionalDate(json, 'deadline'),
    startsOn: _optionalDate(json, 'starts_on'),
    applicationUrl: _optionalText(json, 'application_url'),
  );
}

abstract interface class PublicContentRepository {
  Future<List<CscEvent>> events({required int offset, int limit = 20});
  Future<List<CommunityUpdate>> updates({required int offset, int limit = 20});
  Future<List<CscResource>> resources({required int offset, int limit = 20});
  Future<List<CscOpportunity>> opportunities({
    required int offset,
    int limit = 20,
  });
}

enum ContentFailureKind {
  offline,
  unauthorized,
  forbidden,
  server,
  invalidResponse,
}

class PublicContentException implements Exception {
  const PublicContentException(this.kind);

  final ContentFailureKind kind;

  String get userMessage => switch (kind) {
    ContentFailureKind.offline =>
      'You appear to be offline. Check your connection and try again.',
    ContentFailureKind.unauthorized ||
    ContentFailureKind.forbidden => 'This content is not available right now.',
    ContentFailureKind.invalidResponse || ContentFailureKind.server =>
      'CSC Circle could not load this content. Please try again.',
  };
}

class SupabasePublicContentRepository implements PublicContentRepository {
  SupabasePublicContentRepository(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;

  static const _eventFields =
      'id,title,category,description,cover_image,starts_at,ends_at,location,venue';
  static const _updateFields =
      'id,slug,title,category,summary,featured,cover_image_path,cover_image_alt,published_at';
  static const _resourceFields =
      'id,slug,title,category,resource_type,summary,tags,external_url,published_at';
  static const _resourceView = 'csc_public_resources';
  static const _opportunityFields =
      'id,title,category,summary,organization,deadline,starts_on,application_url';

  @override
  Future<List<CscEvent>> events({required int offset, int limit = 20}) =>
      _fetch(() async {
        final rows = await _client
            .from('events')
            .select(_eventFields)
            .eq('status', 'published')
            .order('starts_at', ascending: true)
            .range(offset, offset + _boundedLimit(limit) - 1)
            .timeout(const Duration(seconds: 15));
        return _decode(rows, CscEvent.fromJson);
      });

  @override
  Future<List<CommunityUpdate>> updates({
    required int offset,
    int limit = 20,
  }) => _fetch(() async {
    final rows = await _client
        .from('community_updates')
        .select(_updateFields)
        .eq('publication_status', 'published')
        .order('featured', ascending: false)
        .order('published_at', ascending: false)
        .range(offset, offset + _boundedLimit(limit) - 1)
        .timeout(const Duration(seconds: 15));
    return _decode(rows, CommunityUpdate.fromJson);
  });

  @override
  Future<List<CscResource>> resources({required int offset, int limit = 20}) =>
      _fetch(() async {
        final end = offset + _boundedLimit(limit) - 1;
        List<dynamic> rows;
        try {
          rows = await _client
              .from(_resourceView)
              .select(_resourceFields)
              .eq('publication_status', 'published')
              .order('published_at', ascending: false)
              .range(offset, end)
              .timeout(const Duration(seconds: 15));
        } on PostgrestException catch (error) {
          // Staged rollout: the approved view is added first; this app can
          // consume it when available and retain the current least-column
          // base-table request until then. Never fall back on authorization,
          // connectivity, or other query failures.
          if (error.code != 'PGRST205' && error.code != '42P01') rethrow;
          rows = await _client
              .from('resources')
              .select(_resourceFields)
              .eq('publication_status', 'published')
              .order('published_at', ascending: false)
              .range(offset, end)
              .timeout(const Duration(seconds: 15));
        }
        return _decode(rows, CscResource.fromJson);
      });

  @override
  Future<List<CscOpportunity>> opportunities({
    required int offset,
    int limit = 20,
  }) => _fetch(() async {
    final today = _todayInIndia(_now());
    final rows = await _client
        .from('opportunities')
        .select(_opportunityFields)
        .eq('publication_status', 'published')
        .or('deadline.is.null,deadline.gte.$today')
        .order('deadline', ascending: true, nullsFirst: false)
        .order('published_at', ascending: false)
        .range(offset, offset + _boundedLimit(limit) - 1)
        .timeout(const Duration(seconds: 15));
    return _decode(rows, CscOpportunity.fromJson);
  });

  Future<T> _fetch<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PublicContentException {
      rethrow;
    } on SocketException {
      throw const PublicContentException(ContentFailureKind.offline);
    } on TimeoutException {
      throw const PublicContentException(ContentFailureKind.offline);
    } on PostgrestException catch (error) {
      final kind = switch (error.code) {
        '401' || 'PGRST301' => ContentFailureKind.unauthorized,
        '403' || '42501' => ContentFailureKind.forbidden,
        _ => ContentFailureKind.server,
      };
      throw PublicContentException(kind);
    } on FormatException {
      throw const PublicContentException(ContentFailureKind.invalidResponse);
    } on Object {
      throw const PublicContentException(ContentFailureKind.server);
    }
  }
}

int _boundedLimit(int limit) => limit.clamp(1, 50);

List<T> _decode<T>(
  List<dynamic> rows,
  T Function(Map<String, dynamic>) parse,
) => rows.map((row) => parse(Map<String, dynamic>.from(row as Map))).toList();

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required field: $key');
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) =>
    _optionalDate(json, key) ?? (throw FormatException('Missing date: $key'));

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid date: $key');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid date: $key');
  return parsed;
}

String _todayInIndia([DateTime? now]) {
  final indiaTime = (now ?? DateTime.now().toUtc()).toUtc().add(
    const Duration(hours: 5, minutes: 30),
  );
  final month = indiaTime.month.toString().padLeft(2, '0');
  final day = indiaTime.day.toString().padLeft(2, '0');
  return '${indiaTime.year}-$month-$day';
}
