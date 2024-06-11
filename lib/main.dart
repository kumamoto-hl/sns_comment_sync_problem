// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Comments'),
              Tab(text: 'Comments2'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CommentListPage(),
            CommentList2Page(),
          ],
        ),
      ),
    );
  }
}

class CommentListPage extends ConsumerWidget {
  const CommentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentIdsAsyncValue = ref.watch(commentsProvider);

    return commentIdsAsyncValue.when(
      data: (commentIds) {
        return ListView.builder(
          itemCount: commentIds.length,
          itemBuilder: (context, index) {
            final comment = ref
                .watch(allCommentsProvider)
                .firstWhere((comment) => comment.id == commentIds[index]);
            return ListTile(
              title: Text(comment.name),
              subtitle: Text(comment.comment),
              trailing: IconButton(
                icon: Icon(
                  comment.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () {
                  final updatedComment =
                      comment.copyWith(isBookmarked: !comment.isBookmarked);
                  ref
                      .read(allCommentsProvider.notifier)
                      .updateComment(updatedComment);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentDetailPage(comment.id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class CommentList2Page extends ConsumerWidget {
  const CommentList2Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentIdsAsyncValue = ref.watch(comments2Provider);

    return commentIdsAsyncValue.when(
      data: (commentIds) => ListView.builder(
        itemCount: commentIds.length,
        itemBuilder: (context, index) {
          final comment = ref
              .watch(allCommentsProvider)
              .firstWhere((comment) => comment.id == commentIds[index]);
          return ListTile(
            title: Text(comment.name),
            subtitle: Text(comment.comment),
            trailing: IconButton(
              icon: Icon(
                comment.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              onPressed: () {
                final updatedComment =
                    comment.copyWith(isBookmarked: !comment.isBookmarked);
                ref
                    .read(allCommentsProvider.notifier)
                    .updateComment(updatedComment);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentDetailPage(comment.id),
                ),
              );
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class CommentDetailPage extends ConsumerWidget {
  final String commentId;

  const CommentDetailPage(this.commentId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comment = ref
        .watch(allCommentsProvider)
        .firstWhere((comment) => comment.id == commentId);

    return Scaffold(
      appBar: AppBar(title: const Text('Comment Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.name, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text(comment.comment),
            const SizedBox(height: 16),
            IconButton(
              icon: Icon(
                comment.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              onPressed: () {
                final updatedComment =
                    comment.copyWith(isBookmarked: !comment.isBookmarked);
                ref
                    .read(allCommentsProvider.notifier)
                    .updateComment(updatedComment);
              },
            ),
          ],
        ),
      ),
    );
  }
}
