import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';

/// 채팅 메시지 입력 박스
///
/// TODO - 업로드 progress bar 를 이 위젯에 직접 표시 할 것.
class ChatMessageInputBox extends StatefulWidget {
  const ChatMessageInputBox({
    super.key,
    this.cameraIcon,
    this.sendIcon,
    this.onProgress,
    this.onSend,
  });

  final Widget? cameraIcon;
  final Widget? sendIcon;

  final Function(double?)? onProgress;

  /// [double] is null when upload is completed.
  final void Function({String? text, String? url})? onSend;

  @override
  State<ChatMessageInputBox> createState() => _ChatMessageInputBoxState();
}

class _ChatMessageInputBoxState extends State<ChatMessageInputBox> {
  final inputController = TextEditingController();
  double? progress;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress != null && !progress!.isNaN) LinearProgressIndicator(value: progress),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: inputController,
            decoration: InputDecoration(
              isDense: false,
              contentPadding: const EdgeInsets.only(
                top: 7,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '메시지를 입력하세요.',
              prefixIcon: IconButton(
                icon: widget.cameraIcon ?? const Icon(Icons.camera_alt),
                onPressed: () async {
                  final url = await StorageService.instance.upload(
                    context: context,
                    // Review
                    camera: true,
                    gallery: true,
                    progress: (p) =>
                        widget.onProgress?.call(p) ?? mounted ? setState(() => progress = p) : null,
                    complete: () => widget.onProgress?.call(null) ?? mounted
                        ? setState(() => progress = null)
                        : null,
                  );
                  await ChatService.instance.sendMessage(url: url);
                  widget.onSend?.call(text: null, url: url);
                },
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: widget.sendIcon ?? const Icon(Icons.send),
                    onPressed: () async {
                      String text = inputController.text.trim();
                      if (text.isEmpty) return;
                      await ChatService.instance.sendMessage(text: text);
                      inputController.clear();
                      widget.onSend?.call(text: text, url: null);
                    },
                  ),
                ],
              ),
            ),
            minLines: 1,
            maxLines: 5,
          ),
        ),
      ],
    );
  }
}
