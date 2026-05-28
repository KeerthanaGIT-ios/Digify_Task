import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Skeleton for horizontal trending carousel
  static Widget trendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: LoadingSkeleton(width: 150, height: 24),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: LoadingSkeleton(
                  width: 150,
                  height: 220,
                  borderRadius: 12,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Skeleton for a grid list
  static Widget movieGrid({int count = 6, required BuildContext context}) {
    // Dynamic column layout
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 5 : (width > 600 ? 4 : 3);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.67,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return const LoadingSkeleton(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 12,
        );
      },
    );
  }

  /// Details page skeleton
  static Widget details() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(
            width: double.infinity,
            height: 380,
            borderRadius: 0,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(width: 250, height: 32),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    LoadingSkeleton(width: 60, height: 20),
                    SizedBox(width: 12),
                    LoadingSkeleton(width: 80, height: 20),
                    SizedBox(width: 12),
                    LoadingSkeleton(width: 50, height: 20),
                  ],
                ),
                const SizedBox(height: 24),
                const LoadingSkeleton(width: 100, height: 20),
                const SizedBox(height: 12),
                ...List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: LoadingSkeleton(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
