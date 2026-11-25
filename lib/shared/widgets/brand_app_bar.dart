import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/constants/asset_paths.dart';

/// App bar with the Futuremug logo and word mark, used on the sign-in and
/// sign-up screens.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              AssetPaths.appIcon,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              semanticLabel: 'Futuremug logo',
            ),
          ),
          const SizedBox(width: 10),
          const Text('futuremug'),
        ],
      ),
      actions: actions,
    );
  }
}
