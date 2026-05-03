import 'dart:ui';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comments/widgets/title.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/ios/sf_symbol_icon.dart';

class ComicReadAppBar extends StatelessWidget {
  final String title;
  final ValueChanged<int> changePageIndex;

  const ComicReadAppBar({
    super.key,
    required this.title,
    required this.changePageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isMenuVisible = context.select(
      (ReaderCubit cubit) => cubit.state.isMenuVisible,
    );
    final colorScheme = context.theme.colorScheme;
    const appBarRadius = 14.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isMenuVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          offset: isMenuVisible ? Offset.zero : const Offset(0, -1),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(appBarRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: AppBar(
                title: ScrollableTitle(text: title),
                titleSpacing: 6,
                leading: Platform.isIOS
                    ? IconButton(
                        icon: const SfSymbolIcon(
                          'chevron.backward',
                          fallback: CupertinoIcons.chevron_back,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    : null,
                backgroundColor: Platform.isIOS
                    ? Colors.black.withValues(alpha: 0.28)
                    : colorScheme.surface.withValues(alpha: 0.78),
                foregroundColor: Platform.isIOS ? Colors.white : null,
                surfaceTintColor: Colors.transparent,
                elevation: isMenuVisible ? 4.0 : 0.0,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(appBarRadius),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
