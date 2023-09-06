import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

/// Display users who are not inside the room
///
/// [searchText] Use this to search in a list of users
/// [exemptedUsers] Array of uids who are exempted in search results
///
/// [itemBuilder] The builder when we want fully customized view per user.
///
class UserListView extends StatelessWidget with FirebaseHelper {
  const UserListView({
    super.key,
    this.searchText,
    this.exemptedUsers = const [],
    this.field = 'displayName',
    this.onTap,
    this.onLongPress,
    this.avatarBuilder,
    this.titleBuilder,
    this.subtitleBuilder,
    this.trailingBuilder,
    this.itemBuilder,
  });

  final String? searchText;
  final List<String> exemptedUsers;
  final Function(User)? onTap;
  final Function(User)? onLongPress;
  final String field;
  final Widget Function(User?)? avatarBuilder;
  final Widget Function(User?)? titleBuilder;
  final Widget Function(User?)? subtitleBuilder;
  final Widget Function(User?)? trailingBuilder;
  final Widget Function(User?)? itemBuilder;

  bool get hasSearchText => searchText != null && searchText != '';

  @override
  Widget build(BuildContext context) {
    Query query = userSearchCol;
    if (hasSearchText) {
      query = query.where(field, isEqualTo: searchText);
    }
    return FirestoreListView(
      query: query,
      itemBuilder: (context, snapshot) {
        final user = User.fromDocumentSnapshot(snapshot);
        if (exemptedUsers.contains(user.uid)) return const SizedBox();
        if (itemBuilder != null) return itemBuilder!.call(user);
        return ListTile(
          title: titleBuilder?.call(user) ?? Text(user.toMap()[field] ?? ''),
          subtitle: subtitleBuilder?.call(user) ?? Text(user.createdAt.toString()),
          leading: avatarBuilder?.call(user) ?? UserAvatar(user: user),
          trailing: trailingBuilder?.call(user) ?? const Icon(Icons.chevron_right),
          onTap: () {
            onTap?.call(user);
          },
          onLongPress: () {
            onLongPress?.call(user);
          },
        );
      },
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
