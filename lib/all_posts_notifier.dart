import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'post.dart';

final loginIdProvider = StateProvider<int>((ref) => 1);

final dioProvider = Provider<Dio>((ref) {
  final loginId = ref.watch(loginIdProvider);
  return Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    headers: {'user-id': loginId.toString()},
  ));
});

final allPostsProvider =
    StateNotifierProvider.autoDispose<AllPostsNotifier, List<Post>>((ref) {
  return AllPostsNotifier();
});

class AllPostsNotifier extends StateNotifier<List<Post>> {
  AllPostsNotifier() : super([]);

  void updatePostWith(List<Post> posts) {
    final Map<int, Post> postMap = {for (var post in state) post.id: post};

    for (var post in posts) {
      postMap[post.id] = post;
    }

    state = postMap.values.toList();
  }

  void removePost(int postId) {
    state = state.where((post) => post.id != postId).toList();
  }
}

class PagedPostsNotifier extends AsyncNotifier<List<int>> {
  int currentPage = 1;
  @override
  Future<List<int>> build() async {
    return await _fetchPosts(currentPage);
  }

  Future<List<int>> _fetchPosts(int page) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/posts', queryParameters: {'page': page});
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;

    final List<dynamic> postsData = data['posts'] as List<dynamic>;

    final posts = postsData
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();

    ref.read(allPostsProvider.notifier).updatePostWith(posts);
    final newPosts = posts.map((post) => post.id).toList();

    return newPosts;
  }

  Future<void> fetchNextPage() async {
    state = state.whenData((existingPosts) => [...existingPosts]);

    state = await AsyncValue.guard(() async {
      currentPage++;
      final newPosts = await _fetchPosts(currentPage);
      return [...state.value ?? [], ...newPosts];
    });
  }

  Future<void> reset() async {
    currentPage = 1;
    state = await AsyncValue.guard(() async {
      return await _fetchPosts(currentPage);
    });
  }
}

final postIdsProvider = AsyncNotifierProvider<PagedPostsNotifier, List<int>>(
    PagedPostsNotifier.new);

final postDetailIdProvider =
    FutureProvider.autoDispose.family<int, int>((ref, postId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/posts/$postId');

  final data = response.data;
  final post = Post.fromJson(data['post']);

  ref.read(allPostsProvider.notifier).updatePostWith([post]);

  return post.id;
});

final bookmarksIdsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final dio = ref.read(dioProvider);
  final loginId = ref.read(loginIdProvider);
  final response = await dio.get('/bookmarks/$loginId');
  final Map<String, dynamic> data = response.data as Map<String, dynamic>;

  final List<dynamic> bookmarksData = data['bookmarks'] as List<dynamic>;

  final bookmarks = bookmarksData
      .map((json) => Post.fromJson(json as Map<String, dynamic>))
      .toList();
  ref.read(allPostsProvider.notifier).updatePostWith(bookmarks);

  return bookmarks.map((bookmark) => bookmark.id).toList();
});

Future<void> toggleBookmark(
    WidgetRef ref, int userId, int postId, bool isBookmarked) async {
  final dio = ref.read(dioProvider);

  if (isBookmarked) {
    await dio.delete('/bookmarks', data: {'userId': userId, 'postId': postId});
  } else {
    await dio.post('/bookmarks', data: {'userId': userId, 'postId': postId});
  }
}
