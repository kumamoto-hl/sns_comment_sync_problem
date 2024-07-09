import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required int id,
    required String name,
    required String comment,
    required bool isBookmarked,
  }) = _Comment;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
