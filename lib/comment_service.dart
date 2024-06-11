import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_model.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
});

final allCommentsProvider =
    StateNotifierProvider<AllCommentsNotifier, List<Comment>>((ref) {
  return AllCommentsNotifier();
});

class AllCommentsNotifier extends StateNotifier<List<Comment>> {
  AllCommentsNotifier() : super([]);

  void setComments(List<Comment> comments) {
    final Map<String, Comment> commentMap = {
      for (var comment in state) comment.id: comment
    };

    for (var comment in comments) {
      commentMap[comment.id] = comment;
    }

    state = commentMap.values.toList();
  }

  void updateComment(Comment comment) {
    state = [
      for (final c in state)
        if (c.id == comment.id) comment else c
    ];
  }

  Comment? getCommentById(String id) {
    return state.firstWhere((comment) => comment.id == id);
  }
}

final commentsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/comments');
  final data = response.data as List;

  final comments = data.map((json) => Comment.fromJson(json)).toList();
  ref.read(allCommentsProvider.notifier).setComments(comments);

  return comments.map((comment) => comment.id).toList();
});

final comments2Provider = FutureProvider.autoDispose<List<String>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/comments2');
  final data = response.data as List;

  final comments = data.map((json) => Comment.fromJson(json)).toList();
  ref.read(allCommentsProvider.notifier).setComments(comments);

  return comments.map((comment) => comment.id).toList();
});
