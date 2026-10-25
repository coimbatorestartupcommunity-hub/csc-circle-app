import 'package:flutter/material.dart';

import '../../core/backend/public_content.dart';
import '../../core/design/app_theme.dart';

class PublicContentPage extends StatefulWidget {
  const PublicContentPage({
    super.key,
    required this.kind,
    required this.repository,
  });

  final PublicContentKind kind;
  final PublicContentRepository? repository;

  @override
  State<PublicContentPage> createState() => _PublicContentPageState();
}

class _PublicContentPageState extends State<PublicContentPage> {
  static const _pageSize = 20;

  final List<PublicContentItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) _load();
  }

  String get _title => switch (widget.kind) {
    PublicContentKind.events => 'CSC Circle events',
    PublicContentKind.updates => 'Community updates',
    PublicContentKind.resources => 'Community resources',
    PublicContentKind.opportunities => 'Current opportunities',
  };

  Future<List<PublicContentItem>> _fetch(int offset) {
    final repository = widget.repository!;
    return switch (widget.kind) {
      PublicContentKind.events => repository.events(
        offset: offset,
        limit: _pageSize,
      ),
      PublicContentKind.updates => repository.updates(
        offset: offset,
        limit: _pageSize,
      ),
      PublicContentKind.resources => repository.resources(
        offset: offset,
        limit: _pageSize,
      ),
      PublicContentKind.opportunities => repository.opportunities(
        offset: offset,
        limit: _pageSize,
      ),
    };
  }

  Future<void> _load({bool append = false}) async {
    if (_loading || widget.repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await _fetch(append ? _items.length : 0);
      if (!mounted) return;
      setState(() {
        if (!append) _items.clear();
        _items.addAll(next);
        _hasMore = next.length == _pageSize;
      });
    } on PublicContentException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'CSC Circle could not load this content. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: widget.repository == null
          ? _PreviewState(title: _title)
          : RefreshIndicator(
              onRefresh: () => _load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CscSpacing.md,
                  CscSpacing.md,
                  CscSpacing.md,
                  CscSpacing.xxl,
                ),
                children: [
                  if (_error != null)
                    _LoadError(message: _error!, onRetry: _load)
                  else if (_items.isEmpty && _loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_items.isEmpty)
                    _EmptyState(title: _title)
                  else ...[
                    for (final item in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: CscSpacing.sm),
                        child: _ContentCard(item: item),
                      ),
                    if (_hasMore)
                      Center(
                        child: TextButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _load(append: true),
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(_loading ? 'Loading' : 'Load more'),
                        ),
                      ),
                  ],
                  if (_error != null && _items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: CscSpacing.md),
                      child: Text(
                        _error!,
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item});

  final PublicContentItem item;

  IconData get _icon => switch (item) {
    CscEvent() => Icons.event_available_rounded,
    CommunityUpdate() => Icons.auto_awesome_rounded,
    CscResource() => Icons.menu_book_rounded,
    CscOpportunity() => Icons.lightbulb_outline_rounded,
  };

  String? get _metadata => switch (item) {
    CscEvent event => '${event.category} · ${event.location}',
    CommunityUpdate update => update.category,
    CscResource resource => '${resource.category} · ${resource.resourceType}',
    CscOpportunity opportunity =>
      opportunity.organization == null
          ? opportunity.category
          : '${opportunity.category} · ${opportunity.organization}',
  };

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    final date = item.date;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CscSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.lavender,
                borderRadius: BorderRadius.circular(CscRadius.control),
              ),
              child: Icon(_icon, color: palette.ink),
            ),
            const SizedBox(width: CscSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: CscSpacing.xs),
                  Text(
                    _metadata ?? '',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: palette.accent),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: CscSpacing.xs),
                    Text(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(date.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.muted),
                    ),
                  ],
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: CscSpacing.sm),
                    Text(
                      item.summary,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: palette.secondary, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewState extends StatelessWidget {
  const _PreviewState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(CscSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: CscSpacing.md),
          Text('$title are not connected in this preview build.'),
          const SizedBox(height: CscSpacing.xs),
          const Text('No sample or unpublished content is shown.'),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Text('There are no published $title to show right now.'),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(CscSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: CscSpacing.sm),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
