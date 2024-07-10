import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
      title: 'Simple SNS App',
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

        ref
            .read(allPostsProvider.notifier)
            .updatePost(post.copyWith(isBookmarked: newBookmarkStatus));
        try {
          await toggleBookmark(ref, userId, post.id, post.isBookmarked);
        } catch (e) {
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
    final postIdsAsync = ref.watch(postIdsProvider);
    final scrollController = useScrollController();
    final posts = ref.watch(
      allPostsProvider.select(
        (posts) {
          final postIds = postIdsAsync.maybeWhen(
            data: (ids) => ids,
            orElse: () => [],
          );
          return posts.where((post) => postIds.contains(post.id)).toList();
        },
      ),
    );

    Future<void> refresh() async {
      ref.read(postIdsProvider.notifier).reset();
    }

    void fetchNextPage() {
      ref.read(postIdsProvider.notifier).fetchNextPage();
    }

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.atEdge &&
            scrollController.position.pixels != 0) {
          fetchNextPage();
        }
      });
      return null;
    }, [scrollController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Feed'),
        actions: [
          PopupMenuButton<int>(
            child: const Icon(Icons.bug_report),
            onSelected: (id) {
              ref.read(loginIdProvider.notifier).state = id;
              ref.read(postIdsProvider.notifier).reset();
              ref.invalidate(allPostsProvider);
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
      body: RefreshIndicator(
        onRefresh: refresh,
        child: postIdsAsync.when(
          data: (postIds) {
            return ListView.builder(
              controller: scrollController,
              itemCount: postIds.length,
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return Container();
                }

                final post = posts[index];
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

class PostDetailScreen extends ConsumerWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postDetailAsync = ref.watch(postDetailIdProvider(postId));
    final postDetail = ref.watch(
      allPostsProvider.select(
        (posts) => posts.firstWhereOrNull((post) => post.id == postId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final dio = ref.read(dioProvider);
              try {
                await dio.delete('/posts/$postId');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
              ref.read(allPostsProvider.notifier).removePost(postId);
            },
          ),
        ],
      ),
      body: postDetailAsync.when(
        data: (id) {
          if (postDetail == null) {
            return const Center(child: Text('Post not found'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(postDetail.name, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Text(postDetail.comment, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                BookmarkButton(post: postDetail),
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
    final bookmarks = ref.watch(bookmarksIdsProvider);
    final _ = ref.watch(allPostsProvider);

    Future<void> refresh() async {
      ref.invalidate(bookmarksIdsProvider);
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
