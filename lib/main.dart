import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sns_comment_sync_problem/post.dart';

import 'all_posts_notifier.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple SNS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PostFeedScreen(),
    );
  }
}

class BookmarkButton extends ConsumerWidget {
  final Post post;

  const BookmarkButton({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(post.isBookmarked ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () async {
        final userId = ref.read(loginIdProvider);
        final newBookmarkStatus = !post.isBookmarked;

        // 楽観的な更新
        ref
            .read(allPostsProvider.notifier)
            .updatePost(post.copyWith(isBookmarked: newBookmarkStatus));
        try {
          await toggleBookmark(ref, userId, post.id, post.isBookmarked);
        } catch (e) {
          // エラーが発生した場合、元の状態に戻す
          ref
              .read(allPostsProvider.notifier)
              .updatePost(post.copyWith(isBookmarked: !newBookmarkStatus));
        }
      },
    );
  }
}

class PostFeedScreen extends HookConsumerWidget {
  const PostFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postIdsAsync = ref.watch(postsProvider);
    final _ = ref.watch(allPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Feed'),
        actions: [
          PopupMenuButton<int>(
            child: Text("Login as: ${ref.watch(loginIdProvider)}"),
            onSelected: (id) {
              ref.read(loginIdProvider.notifier).state = id;
              ref.invalidate(postsProvider);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Login as User 1')),
              const PopupMenuItem(value: 2, child: Text('Login as User 2')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookmarkListScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: postIdsAsync.when(
        data: (postIds) {
          return ListView.builder(
            itemCount: postIds.length,
            itemBuilder: (context, index) {
              final post = ref
                  .read(allPostsProvider.notifier)
                  .getPostById(postIds[index]);
              if (post == null) {
                return Container();
              }
              // final post = posts[index];
              return ListTile(
                title: Text(post.name),
                subtitle: Text(post.comment),
                trailing: BookmarkButton(post: post),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class PostDetailScreen extends ConsumerWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postDetail = ref.watch(hoge2Provider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
      ),
      body: postDetail.when(
        data: (post) {
          return post == null
              ? const Center(child: Text('Post not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.name, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 16),
                      Text(post.comment, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      BookmarkButton(post: post),
                    ],
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class BookmarkListScreen extends HookConsumerWidget {
  const BookmarkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksMasterProvider);
    final _ = ref.watch(allPostsProvider);

    Future<void> refresh() async {
      ref.invalidate(bookmarksMasterProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: bookmarks.when(
          data: (posts) {
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = ref
                    .read(allPostsProvider.notifier)
                    .getPostById(posts[index]);
                if (post == null) {
                  return Container();
                }
                // final post = posts[index];
                return ListTile(
                  title: Text(post.name),
                  subtitle: Text(post.comment),
                  trailing: BookmarkButton(post: post),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: post.id),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
