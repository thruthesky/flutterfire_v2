import 'package:cached_network_image/cached_network_image.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

class MeetupUpdateForm extends StatefulWidget {
  const MeetupUpdateForm({
    super.key,
    required this.meetup,
  });

  final Meetup meetup;

  @override
  State<MeetupUpdateForm> createState() => _ClubUpdateFormState();
}

class _ClubUpdateFormState extends State<MeetupUpdateForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  get meetup => widget.meetup;

  @override
  void initState() {
    super.initState();

    nameController.text = meetup.name;
    descriptionController.text = meetup.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('Meetup ID: ${meetup.id}'),
          // Text('owner uid: ${meetup.uid}'),
          // Text('my Uid: ${UserService.instance.user!.uid}'),
          GestureDetector(
            onTap: () async {
              StorageService.instance.delete(meetup.photoUrl);
              final url = await StorageService.instance.upload(
                context: context,
                progress: (p0) => print(p0),
                complete: () => print('complete'),
              );
              if (url == null) return;

              await meetup.update(photoUrl: url);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MeetupDoc(
                meetup: meetup,
                builder: (Meetup meetup) => Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: meetup.photoUrl.isNullOrEmpty
                      ? Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 100,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: meetup.photoUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            T.meetupPhotoDescription.tr,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 24),
          LabelField(
            controller: nameController,
            label: T.meetupName.tr,
            description: T.meetupNameDescription.tr,
          ),
          LabelField(
            controller: descriptionController,
            label: T.meetupDescriptionLabel.tr,
            description: T.meetupDescriptionInputDescription.tr,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          Align(
            child: OutlinedButton(
              onPressed: () async {
                await meetup.update(
                  name: nameController.text,
                  description: descriptionController.text,
                );
                toast(context: context, message: T.meetupUpdateMessage.tr);
              },
              child: Text(T.meetupUpdate.tr),
            ),
          ),
        ],
      ),
    );
  }
}
