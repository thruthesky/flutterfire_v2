import 'package:fireflutter/fireflutter.dart';
import 'package:fireflutter/src/model/comment.dart';

class CommentService with FirebaseHelper {
  static CommentService? _instance;
  static CommentService get instance => _instance ??= CommentService._();
  CommentService._();

  Future<Comment> createComment({
    required String postId,
    required String content,
    List<String>? files,
    String? replyTo,
  }) {
    return Comment.create(
      postId: postId,
      content: content,
      files: files,
      replyTo: replyTo,
    );
  }
}
