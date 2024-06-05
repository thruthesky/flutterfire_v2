import 'package:cached_network_image/cached_network_image.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

class MeetupDetails extends StatelessWidget {
  const MeetupDetails({
    super.key,
    required this.meetup,
  });

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return MeetupDoc(
      meetup: meetup,
      builder: (meetup) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meetup.photoUrl != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: meetup.photoUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(meetup.description),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ChatService.instance.showChatRoomScreen(
                          context: context,
                          otherUid: meetup.master,
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.chat),
                          const SizedBox(width: 2),
                          Text(T.contact.tr),
                        ],
                      ),
                    ),
                    if (meetup.isMaster) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => MeetupService.instance
                            .showUpdateScreen(context: context, meetup: meetup),
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 2),
                            Text(T.edit.tr),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserDoc(
                                uid: meetup.master,
                                builder: (user) {
                                  return Row(
                                    children: [
                                      Text('${T.host.tr}: ${user.displayName}'),
                                    ],
                                  );
                                },
                              ),
                              Text(
                                  '${T.members.tr}: ${meetup.users.length} ${T.noOfPeople.tr}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (meetup.reminder.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 24),
                        child: Text(T.reminder.tr),
                      ),
                      Card(
                        child: InkWell(
                          onTap: () => alert(
                            context: context,
                            title: T.reminder.tr,
                            message: meetup.reminder,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            child: Text(
                              meetup.reminder.cut(128),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 24),
                child: Text(T.recentPhotos.tr),
              ),
              PostLatestListView.gridView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                category: '${meetup.id}-meetup-gallery',
                emptyBuilder: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                      child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(T.noRecentPhotos.tr)),
                  )),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 24),
                child: Text(T.recentPosts.tr),
              ),
              PostLatestListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (p0, p1) => const SizedBox(height: 8),
                category: '${meetup.id}-meetup-post',
                emptyBuilder: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                      child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(T.noRecentPosts.tr),
                    ),
                  )),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
              const SizedBox(height: 64),
            ],
          ),
        );
      },
    );
  }
}
