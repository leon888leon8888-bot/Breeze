import 'dart:ui';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/page/comic_read/widgets/settings/reader_settings_sheet.dart';
import 'package:zephyr/util/router/router.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/ios/sf_symbol_icon.dart';

class BottomWidget extends StatefulWidget {
  final ComicEntryType type;
  final dynamic comicInfo;
  final Widget sliderWidget;
  final int order;
  final int epsNumber;
  final String comicId;
  final String from;
  final JumpChapter jumpChapter;

  const BottomWidget({
    super.key,
    required this.type,
    required this.comicInfo,
    required this.sliderWidget,
    required this.order,
    required this.epsNumber,
    required this.comicId,
    required this.from,
    required this.jumpChapter,
  });

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  bool get isDownload =>
      widget.type == ComicEntryType.download ||
      widget.type == ComicEntryType.historyAndDownload;

  JumpChapter get jumpChapter => widget.jumpChapter;

  final Duration _animationDuration = const Duration(milliseconds: 300); // 动画时长

  late ComicEntryType tempType;
  late String comicId;
  List<UnifiedComicChapterRef> chapterRefs = [];

  @override
  void initState() {
    super.initState();

    tempType = widget.type;
    comicId = widget.comicId;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
    chapterRefs = resolveUnifiedComicChapters(widget.comicInfo, widget.from);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIosHud(context);
    }
    final isMenuVisible = context.select(
      (ReaderCubit cubit) => cubit.state.isMenuVisible,
    );
    final bottomSafeHeight = context.bottomSafeHeight;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideLayout = screenWidth >= 840;
    final topMaxWidth = (screenWidth * 0.56).clamp(380.0, 720.0).toDouble();
    final bottomMaxWidth = (screenWidth * (screenWidth >= 1200 ? 0.62 : 0.74))
        .clamp(560.0, 980.0)
        .toDouble();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isMenuVisible,
        child: AnimatedSlide(
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          offset: isMenuVisible ? Offset.zero : const Offset(0, 1),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6 + bottomSafeHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideLayout ? topMaxWidth : double.infinity,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChapterNavigationButton(
                            icon: Icons.skip_previous_rounded,
                            tooltip: '上一章',
                            isEnabled: jumpChapter.havePrev,
                            onTap: () => _jumpToChapter(true),
                          ),
                          const SizedBox(width: 10),
                          FloatingActionIconButton(
                            icon: Icons.home_rounded,
                            tooltip: '返回首页',
                            onPressed: () => popToRoot(context),
                          ),
                          const SizedBox(width: 10),
                          FloatingActionIconButton(
                            icon: Icons.list_alt_rounded,
                            tooltip: '跳转章节',
                            isEnabled: chapterRefs.isNotEmpty,
                            onPressed: _selectJumpChapter,
                          ),
                          const SizedBox(width: 10),
                          FloatingActionIconButton(
                            icon: Icons.tune_rounded,
                            tooltip: '阅读设置',
                            onPressed: _openSettingsPanel,
                          ),
                          const SizedBox(width: 10),
                          ChapterNavigationButton(
                            icon: Icons.skip_next_rounded,
                            tooltip: '下一章',
                            isEnabled: jumpChapter.haveNext,
                            onTap: () => _jumpToChapter(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideLayout
                            ? bottomMaxWidth
                            : double.infinity,
                      ),
                      child: Row(children: [widget.sliderWidget]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIosHud(BuildContext context) {
    final isMenuVisible = context.select(
      (ReaderCubit cubit) => cubit.state.isMenuVisible,
    );
    final bottomSafeHeight = context.bottomSafeHeight;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 24).clamp(320.0, 720.0).toDouble();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isMenuVisible,
        child: AnimatedSlide(
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          offset: isMenuVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: _animationDuration,
            opacity: isMenuVisible ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomSafeHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _IosHudButton(
                                    symbolName: 'backward.end.fill',
                                    fallbackIcon:
                                        CupertinoIcons.backward_end_fill,
                                    tooltip: '上一章',
                                    enabled: jumpChapter.havePrev,
                                    onPressed: () => _jumpToChapter(true),
                                  ),
                                  _IosHudButton(
                                    symbolName: 'house.fill',
                                    fallbackIcon: CupertinoIcons.house_fill,
                                    tooltip: '返回首页',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      popToRoot(context);
                                    },
                                  ),
                                  _IosHudButton(
                                    symbolName: 'list.bullet',
                                    fallbackIcon: CupertinoIcons.list_bullet,
                                    tooltip: '章节',
                                    enabled: chapterRefs.isNotEmpty,
                                    onPressed: _selectJumpChapter,
                                  ),
                                  _IosHudButton(
                                    symbolName: 'slider.horizontal.3',
                                    fallbackIcon:
                                        CupertinoIcons.slider_horizontal_3,
                                    tooltip: '阅读设置',
                                    onPressed: _openSettingsPanel,
                                  ),
                                  _IosHudButton(
                                    symbolName: 'forward.end.fill',
                                    fallbackIcon:
                                        CupertinoIcons.forward_end_fill,
                                    tooltip: '下一章',
                                    enabled: jumpChapter.haveNext,
                                    onPressed: () => _jumpToChapter(false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              IconTheme(
                                data: const IconThemeData(color: Colors.white),
                                child: DefaultTextStyle(
                                  style: const TextStyle(color: Colors.white),
                                  child: Row(children: [widget.sliderWidget]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSettingsPanel() {
    final readerCubit = context.read<ReaderCubit>();
    showReaderSettingsSheet(
      context,
      changePageIndex: (int value) {
        readerCubit.updatePageIndex(value);
        readerCubit.updateSliderChanged(0.0);
      },
    );
  }

  Future<bool> _bottomButtonDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 不允许点击外部区域关闭对话框
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 返回 false
                  },
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 返回 true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 处理返回值为空的情况
  }

  Future<void> _jumpToChapter(bool isPrev) async {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    }
    final dialogMessage = isPrev ? '上一章' : '下一章';
    final result = await _bottomButtonDialog(
      context,
      '跳转',
      '是否要跳转到$dialogMessage？',
    );
    if (!result) return;
    if (!mounted) return;
    jumpChapter.jumpToChapter(context, isPrev);
  }

  Future<void> _selectJumpChapter() async {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    }
    final router = AutoRouter.of(context);
    final result = Platform.isIOS
        ? await CupertinoScaffold.showCupertinoModalBottomSheet<int?>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => _IosChapterSheet(
              chapters: chapterRefs,
              onSelected: (order) => Navigator.of(context).pop(order),
            ),
          )
        : await showDialog<int?>(
            context: context,
            barrierDismissible: false, // 不允许点击外部区域关闭对话框
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('选择章节'),
                content: SingleChildScrollView(child: _epSelector(context)),
                actions: [
                  TextButton(
                    child: Text('取消'),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                ],
              );
            },
          );
    if (result != null && mounted) {
      router.replace(
        ComicReadRoute(
          key: Key(Uuid().v4()),
          comicInfo: widget.comicInfo,
          comicId: comicId,
          type: tempType,
          order: result,
          epsNumber: widget.epsNumber,
          from: widget.from,
          stringSelectCubit: context.read<StringSelectCubit>(),
        ),
      );
    }
  }

  Widget _epSelector(BuildContext context) {
    return ListBody(
      children: [
        for (final ep in chapterRefs)
          TextButton(
            child: Text(ep.name),
            onPressed: () =>
                Navigator.of(context, rootNavigator: false).pop(ep.order),
          ),
      ],
    );
  }
}

class _IosChapterSheet extends StatelessWidget {
  final List<UnifiedComicChapterRef> chapters;
  final ValueChanged<int> onSelected;

  const _IosChapterSheet({
    required this.chapters,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择章节',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: chapters.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 20,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return ListTile(
                      title: Text(chapter.name),
                      trailing: const SfSymbolIcon(
                        'chevron.forward',
                        fallback: CupertinoIcons.chevron_forward,
                        size: 16,
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(chapter.order);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IosHudButton extends StatelessWidget {
  final String symbolName;
  final IconData fallbackIcon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _IosHudButton({
    required this.symbolName,
    required this.fallbackIcon,
    required this.tooltip,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minSize: 42,
      onPressed: enabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed();
            }
          : null,
      child: SfSymbolIcon(
        symbolName,
        fallback: fallbackIcon,
        color: enabled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.32),
        size: 22,
        semanticLabel: tooltip,
      ),
    );
  }
}

class ChapterNavigationButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onTap;

  const ChapterNavigationButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return _FrostedCircleIconButton(
      tooltip: tooltip,
      isEnabled: isEnabled,
      onPressed: onTap,
      icon: icon,
      foregroundColor: colorScheme.onSecondaryContainer,
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.72),
      disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.38,
      ),
    );
  }
}

class FloatingActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onPressed;

  const FloatingActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return _FrostedCircleIconButton(
      tooltip: tooltip,
      isEnabled: isEnabled,
      onPressed: onPressed,
      icon: icon,
      foregroundColor: colorScheme.onPrimaryContainer,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.76),
      disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.38,
      ),
    );
  }
}

class _FrostedCircleIconButton extends StatelessWidget {
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onPressed;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color disabledBackgroundColor;

  const _FrostedCircleIconButton({
    required this.tooltip,
    required this.isEnabled,
    required this.onPressed,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.disabledBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: IconButton(
          tooltip: tooltip,
          onPressed: isEnabled ? onPressed : null,
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            shape: const CircleBorder(),
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            disabledForegroundColor: colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            disabledBackgroundColor: disabledBackgroundColor,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
