import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'post.dart';

final loginIdProvider = StateProvider<int>((ref) => 1); // 初期値を1に設定

final dioProvider = Provider<Dio>((ref) {
  final loginId = ref.watch(loginIdProvider);
  return Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    headers: {'user-id': loginId.toString()}, // ログインIDをヘッダーに追加
  ));
});

final allPostsProvider =
    StateNotifierProvider.autoDispose<AllPostsNotifier, List<Post>>((ref) {
  return AllPostsNotifier();
});

class AllPostsNotifier extends StateNotifier<List<Post>> {
  AllPostsNotifier() : super([]);

  void setPosts(List<Post> posts) {
    final Map<int, Post> postMap = {for (var post in state) post.id: post};

    for (var post in posts) {
      postMap[post.id] = post;
    }

    state = postMap.values.toList();
  }

  void updatePost(Post post) {
    state = [
      for (final p in state)
        if (p.id == post.id) post else p
    ];
  }

  Post? getPostById(int id) {
    try {
      return state.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }
}

final hogeProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final _ = ref.watch(allPostsProvider);
  final postIds = await ref.watch(postsProvider.future);

  return postIds
      .map((id) => ref.read(allPostsProvider.notifier).getPostById(id))
      .nonNulls
      .toList();
});

final postsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
//  final allPosts = ref.watch(allPostsProvider.notifier);
  final dio = ref.read(dioProvider);
  final response = await dio.get('/posts');
  final Map<String, dynamic> data = response.data as Map<String, dynamic>;

  final List<dynamic> postsData = data['posts'] as List<dynamic>;

  final posts = postsData
      .map((json) => Post.fromJson(json as Map<String, dynamic>))
      .toList();
  ref.read(allPostsProvider.notifier).setPosts(posts);
  return posts.map((post) => post.id).toList();
//  return posts.map((post) => allPosts.getPostById(post.id)).nonNulls.toList();
});

final hoge2Provider =
    FutureProvider.autoDispose.family<Post?, int>((ref, idd) async {
  final _ = ref.watch(allPostsProvider);
  final id = await ref.watch(postDetailProvider(idd).future);

  return ref.read(allPostsProvider.notifier).getPostById(id);
});

final postDetailProvider =
    FutureProvider.autoDispose.family<int, int>((ref, postId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/posts/$postId');

  final data = response.data;
  final post = Post.fromJson(data['post']);

  ref.read(allPostsProvider.notifier).setPosts([post]);

  return post.id;
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
