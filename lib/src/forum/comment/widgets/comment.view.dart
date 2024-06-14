import 'package:cached_network_image/cached_network_image.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:fireflutter/src/common/photo_view/photo.view.screen.dart';
import 'package:flutter/material.dart';

class CommentView extends StatefulWidget {
  const CommentView({
    super.key,
    required this.post,
    required this.comment,
    this.onCreate,
  });

  final Post post;
  final Comment comment;
  final Function? onCreate;

  @override
  State<CommentView> createState() => _CommentViewState();
}

class _CommentViewState extends State<CommentView> {
  int? previousNoOfLikes;

  double lineWidth = 2;
  Color get verticalLineColor =>
      Colors.red; // Theme.of(context).colorScheme.outline.withAlpha(40);
  Color get curvedLineColor => Colors.green;
  bool get isFirstParent =>
      widget.comment.parentId == null && widget.comment.depth == 0;
  bool get isChild => !isFirstParent;
  bool get hasChild => widget.comment.hasChild;
  bool get hasSibling => widget.comment.hasSiblings;
  bool get lastChild => widget.comment.isLastChild;
  int get depth => widget.comment.depth;

  @override
  Widget build(BuildContext context) {
    /// Intrinsic height is a natural height from its child
    /// Using VerticalDivider, the VerticalDivider will automatically
    /// takes all the space from the parent
    // padding: EdgeInsets.only(left: widget.comment.leftMargin, right: 16),
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.only(left: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < depth; i++) ...[
              const SizedBox(width: 19),
              if (i != depth - 1) ...[
                if (hasSibling || isChild) _verticalLine(),
                const SizedBox(width: 8),
              ]
            ],

            /// curved line
            if (isChild) ...[
              if (!lastChild) _verticalLine(),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(width: lineWidth, color: curvedLineColor),
                    left: BorderSide(width: lineWidth, color: curvedLineColor),
                  ),

                  /// For making a curve to its edge
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                  ),
                ),
              ),
            ],
            Column(
              children: [
                UserAvatar(
                  uid: widget.comment.uid,
                  onTap: () => UserService.instance.showPublicProfileScreen(
                    context: context,
                    uid: widget.comment.uid,
                  ),
                  size: isFirstParent ? 40 : 24,
                ),

                /// the horizontal line
                if (hasChild)
                  Expanded(
                    child: _verticalLine(),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserDisplayName(
                        uid: widget.comment.uid,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        // '${widget.comment.parentId}',
                        widget.comment.createdAt.toShortDate,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                  CommentContent(comment: widget.comment),
                  Blocked(
                    otherUserUid: widget.comment.uid,
                    yes: () => SizedBox.fromSize(),
                    no: () => Wrap(
                      spacing: 14,
                      runSpacing: 14,

                      /// Converts to Map<int,string> first to reveal the item's index
                      /// this is for the PhotoViewer so it will immediately open the image
                      /// that the user pressed
                      children: widget.comment.urls
                          .asMap()
                          .map(
                            (index, url) => MapEntry(
                              index,
                              GestureDetector(
                                onTap: () => showGeneralDialog(
                                  context: context,
                                  pageBuilder: (_, __, ___) =>
                                      PhotoViewerScreen(
                                    urls: widget.comment.urls,
                                    selectedIndex: index,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    width: widget.comment.urls.length == 1
                                        ? 200
                                        : 100,
                                    height: 200,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          textStyle:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    fontWeight: FontWeight.w400,
                                  ),
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -1,
                          ),
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(200),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final re = await ForumService.instance
                                .showCommentCreateScreen(
                              context: context,
                              post: widget.post,
                              parent: widget.comment,
                            );
                            if (re == true) {
                              widget.onCreate?.call();
                            }
                          },
                          child: Text(T.reply.tr),
                        ),
                        TextButton(
                          onPressed: () =>
                              widget.comment.like(context: context),
                          child: Value(
                            ref: widget.comment.likesRef,
                            builder: (likes) {
                              previousNoOfLikes =
                                  (likes as Map? ?? {}).keys.length;
                              return Text(
                                  '${T.like.tr}${likeText(previousNoOfLikes)}');
                            },
                            onLoading: Text(
                                '${T.like.tr}${likeText(previousNoOfLikes)}'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ChatService.instance.showChatRoomScreen(
                              context: context,
                              otherUid: widget.comment.uid,
                            );
                          },
                          child: Text(T.chat.tr),
                        ),
                        // Prevents the overflow from small devices
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: PopupMenuButton(itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  value: 'bookmark',
                                  child: Login(
                                    yes: (uid) => Value(
                                      ref: Bookmark.commentRef(
                                          widget.comment.id),
                                      builder: (v) {
                                        return Text(
                                          v == null
                                              ? T.bookmark.tr
                                              : T.unbookmark.tr,
                                        );
                                      },
                                    ),
                                    no: () => Text(T.bookmark.tr),
                                  ),
                                ),
                                if (widget.comment.uid != myUid)
                                  PopupMenuItem(
                                    value: 'block',
                                    child: Blocked(
                                      otherUserUid: widget.comment.uid,
                                      no: () => Text(T.block.tr),
                                      yes: () => Text(T.unblock.tr),
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'report',
                                  child: Text(T.report.tr),
                                ),
                                if (widget.comment.isMine)
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(T.edit.tr),
                                  ),
                                if (widget.comment.isMine)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(T.delete.tr),
                                  ),
                              ];
                            }, onSelected: (value) async {
                              if (value == 'report') {
                                final re = await input(
                                  context: context,
                                  title: T.reportInputTitle.tr,
                                  subtitle: T.reportInputMessage.tr,
                                  hintText: T.reportInputHint.tr,
                                );
                                if (re == null || re == '') return;
                                await Report.create(
                                  postId: widget.comment.postId,
                                  commentId: widget.comment.id,
                                  reason: re,
                                );
                                if (context.mounted) {
                                  toast(
                                      context: context,
                                      message: T.reportReceived.tr);
                                }
                              } else if (value == 'block') {
                                await UserService.instance.block(
                                  context: context,
                                  otherUserUid: widget.comment.uid,
                                  ask: true,
                                  notify: true,
                                );
                              } else if (value == 'edit') {
                                if (widget.comment.isMine == false) {
                                  return error(
                                    context: context,
                                    message: T.notYourComment.tr,
                                  );
                                }
                                await ForumService.instance
                                    .showCommentUpdateScreen(
                                  context: context,
                                  comment: widget.comment,
                                );
                                widget.post.reload();
                              } else if (value == 'delete') {
                                if (widget.comment.isMine == false) {
                                  return error(
                                    context: context,
                                    message: T.notYourComment.tr,
                                  );
                                }
                                await widget.comment
                                    .delete(context: context, ask: true);
                              } else if (value == 'bookmark') {
                                final re = await Bookmark.toggle(
                                  context: context,
                                  postId: widget.comment.postId,
                                  commentId: widget.comment.id,
                                );
                                if (re != null && context.mounted) {
                                  toast(
                                    context: context,
                                    title: re == true
                                        ? T.bookmark.tr
                                        : T.unbookmark.tr,
                                    message: re == true
                                        ? T.bookmarkMessage.tr
                                        : T.unbookmarkMessage.tr,
                                  );
                                }
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalLine() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: verticalLineColor,
          width: 1,
        ),
      ),
    );
  }
}
