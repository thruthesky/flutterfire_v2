import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

/// Display users who are not inside the room
///
/// [searchText] Use this to search in a list of users
///
/// [field] is the field to be used in the search. If the value of [field]
/// is 'name', then, it will search in the fields 'firstName', 'middleName',
/// 'lastName', 'name', and 'displayName'.
///
///
/// [exemptedUsers] Array of uids who are exempted in search results
///
/// [itemBuilder] The builder when we want fully customized view per user.
///
///
class UserListView extends StatelessWidget {
  const UserListView({
    super.key,
    this.shrinkWrap = false,
    this.physics,
    this.searchText,
    this.query,
    this.exemptedUsers = const [],
    this.orderBy,
    this.descending = false,
    this.field = 'name',
    this.onTap,
    this.onLongPress,
    this.avatarBuilder,
    this.titleBuilder,
    this.subtitleBuilder,
    this.trailingBuilder,
    this.itemBuilder,
    this.listViewPadding,
    this.customViewBuilder,
    this.pageSize = 10,
    this.scrollDirection = Axis.vertical,
    this.contentPadding,
    this.separatorBuilder,
  });

  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? searchText;
  final String field;
  final Query? query;
  final List<String> exemptedUsers;
  final String? orderBy;
  final bool descending;
  final Function(User)? onTap;
  final Function(User)? onLongPress;
  final Widget Function(User)? avatarBuilder;
  final Widget Function(User)? titleBuilder;
  final Widget Function(User)? subtitleBuilder;
  final Widget Function(User)? trailingBuilder;
  final Widget Function(User user, int index)? itemBuilder;
  final EdgeInsetsGeometry? listViewPadding;
  final EdgeInsetsGeometry? contentPadding;
  final Widget Function(int)? separatorBuilder;

  /// Use this [customViewBuilder] to customize what view (listView, gridView, etc) to use.
  /// If decided to use this, [avatarBuilder], [titleBuilder], [subtitleBuilder],
  /// [trailingBuilder], [itemBuilder], [scrollDirection], [pageSize], [onTap], and [onLongPress]
  ///  will have no effect.
  ///
  /// Must add these codes to the customViewBuilder if you want to fetch more items:
  /// ```dart
  /// if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
  ///   snapshot.fetchMore();
  /// }
  /// ```
  final Widget Function(FirestoreQueryBuilderSnapshot<Object?> snapshot)? customViewBuilder;

  final Axis scrollDirection;

  final int pageSize;

  // bool get hasSearchText => searchText != null;
  bool get hasOrderBy => orderBy != null && orderBy != '';

  Query? get searchQuery {
    Query q = userCol;

    if (searchText != null && searchText != '') {
      if (field == 'name') {
        q = userCol.where(
          Filter.or(
            Filter('firstName', isEqualTo: searchText),
            Filter('middleName', isEqualTo: searchText),
            Filter('lastName', isEqualTo: searchText),
            Filter('name', isEqualTo: searchText),
            Filter('displayName', isEqualTo: searchText),
          ),
        );
      } else {
        q = userCol.where(field, isEqualTo: searchText);
      }
    }
    if (hasOrderBy) {
      q = q.orderBy(orderBy!, descending: descending);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    return FirestoreQueryBuilder(
      pageSize: pageSize,
      query: query ?? searchQuery ?? userCol,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          return Text('Something went wrong! ${snapshot.error}');
        }
        snapshot.docs.removeWhere((doc) => exemptedUsers.contains(doc.id));
        snapshot.docs.removeWhere((doc) => !(User.fromDocumentSnapshot(doc).exists));
        if (customViewBuilder != null) return customViewBuilder!.call(snapshot);
        return ListView.separated(
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: listViewPadding,
          separatorBuilder: (context, index) =>
              separatorBuilder?.call(index) ??
              Divider(
                color: Theme.of(context).colorScheme.secondary.withAlpha(40),
              ),
          scrollDirection: scrollDirection,
          itemCount: snapshot.docs.length,
          itemBuilder: (context, index) {
            // if we reached the end of the currently obtained items, we try to
            // obtain more items
            if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
              // Tell FirestoreQueryBuilder to try to obtain more items.
              // It is safe to call this function from within the build method.
              snapshot.fetchMore();
            }
            final user = User.fromDocumentSnapshot(snapshot.docs[index]);
            // add user to cache?
            // This will prevent lots of loading for UserDoc Widget
            // Please update if we have better solution.
            UserService.instance.userCache[user.uid] = user;
            if (itemBuilder != null) return itemBuilder!.call(user, index);
            return ListTile(
              contentPadding: contentPadding,
              title: titleBuilder?.call(user) ?? Text(user.toMap()[field] ?? ''),
              subtitle: subtitleBuilder?.call(user) ?? Text(user.createdAt.toString()),
              leading: avatarBuilder?.call(user) ?? UserAvatar(user: user, size: 48),
              trailing: trailingBuilder?.call(user) ?? const Icon(Icons.chevron_right),
              onTap: () async {
                onTap?.call(user);
              },
              onLongPress: () async {
                onLongPress?.call(user);
              },
            );
          },
        );
      },
    );
  }

  /// Use this builder when you already got a list of uids.
  static Widget builder({
    Key? key,
    required List<String> uids,
    Widget Function(User? user)? itemBuilder,
    Widget Function(User? user)? notExistBuilder,
    Widget Function()? loadingBuilder,
  }) {
    return ListView.builder(
      key: key,
      itemCount: uids.length,
      itemBuilder: (context, index) {
        return UserDoc(
          uid: uids[index],
          onLoading: loadingBuilder?.call() ??
              const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading...'),
              ),
          builder: (user) {
            if (!user.exists) {
              return notExistBuilder?.call(user) ?? const SizedBox.shrink();
            }
            return itemBuilder?.call(user) ??
                ListTile(
                  leading: UserAvatar(user: user),
                  title: Text(user.getDisplayName),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    UserService.instance.showPublicProfileScreen(context: context, user: user);
                  },
                );
          },
        );
      },
    );
  }
}
