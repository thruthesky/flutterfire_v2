import 'package:cached_network_image/cached_network_image.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

class CarouselView extends StatefulWidget {
  const CarouselView({
    super.key,
    this.urls,
    this.widgets,
    this.index = 0,
    this.showPageCounter = true,
    this.height = 400,
    this.onPageChanged,
    this.controller,
  }) : assert(urls != null || widgets != null);

  final List<String>? urls;
  final List<Widget>? widgets;
  final int index;
  final bool showPageCounter;
  final double height;
  final void Function(int)? onPageChanged;
  final PageController? controller;

  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  PageController? _controller;
  late int pageNo;
  bool isVisible = false;

  PageController get controller => widget.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController(initialPage: widget.index);
    pageNo = widget.index + 1;
    controller.addListener(pageChange);
  }

  @override
  void dispose() {
    controller.removeListener(pageChange);
    // let the parent widget handle the disposal controller
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  pageChange() {
    if (controller.page == null) return;
    if (controller.page == controller.page!.roundToDouble()) {
      setState(() {
        pageNo = controller.page!.round() + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          PageView(
            controller: controller,
            onPageChanged: widget.onPageChanged,
            children: widget.widgets ??
                widget.urls!
                    .asMap()
                    .entries
                    .map((e) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            StorageService.instance.showUploads(
                              context,
                              widget.urls!,
                              index: e.key,
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: e.value,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(height: 400),
                          ),
                        ))
                    .toList(),
          ),
          if (widget.showPageCounter)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.only(top: sizeXs, right: sizeXs),
                padding: const EdgeInsets.symmetric(vertical: sizeXxs - 1, horizontal: sizeXs),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onBackground.withAlpha(150),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$pageNo/${widget.widgets?.length ?? widget.urls!.length}',
                  style: TextStyle(color: Theme.of(context).colorScheme.background),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
