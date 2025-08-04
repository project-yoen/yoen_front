import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class ResponsiveShimmerImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio; // 예: 16 / 9
  final double borderRadius;

  const ResponsiveShimmerImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          placeholderFadeInDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) {
            return FutureBuilder<LottieComposition>(
              future: AssetLottie('assets/lotties/shimmer_image.json').load(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Lottie(
                    composition: snapshot.data!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  );
                } else {
                  return const SizedBox(
                    width: 100,
                    height: 100,
                  ); // or a spinner
                }
              },
            );
          },
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
