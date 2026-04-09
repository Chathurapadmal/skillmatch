import 'package:flutter/material.dart';
import 'package:skillmatch/services/image_service.dart';

class SupabaseImageWidget extends StatefulWidget {
  final String? storagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final bool isCircular;
  final double? radius;

  const SupabaseImageWidget({
    Key? key,
    required this.storagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.isCircular = false,
    this.radius,
  }) : super(key: key);

  @override
  State<SupabaseImageWidget> createState() => _SupabaseImageWidgetState();
}

class _SupabaseImageWidgetState extends State<SupabaseImageWidget> {
  late Future<String?> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _generateUrl();
  }

  @override
  void didUpdateWidget(SupabaseImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _urlFuture = _generateUrl();
    }
  }

  Future<String?> _generateUrl() async {
    if (widget.storagePath == null || widget.storagePath!.isEmpty) {
      return null;
    }
    return ImageService.getProfileImageUrl(widget.storagePath!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storagePath == null || widget.storagePath!.isEmpty) {
      return widget.isCircular
          ? CircleAvatar(
              radius: widget.radius,
              child: const Icon(Icons.image),
            )
          : Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Icon(Icons.image),
            );
    }

    return FutureBuilder<String?>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.isCircular
              ? CircleAvatar(
                  radius: widget.radius,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Container(
                  width: widget.width,
                  height: widget.height,
                  color: Colors.grey[200],
                  child: const CircularProgressIndicator(),
                );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return widget.isCircular
              ? CircleAvatar(
                  radius: widget.radius,
                  child: const Icon(Icons.broken_image),
                )
              : Container(
                  width: widget.width,
                  height: widget.height,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                );
        }

        final imageUrl = snapshot.data!;

        if (widget.isCircular) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundImage: NetworkImage(imageUrl),
          );
        }

        return Image.network(
          imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            );
          },
        );
      },
    );
  }
}
