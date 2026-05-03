import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sf_symbols/sf_symbols.dart';

class SfSymbolIcon extends StatelessWidget {
  final String name;
  final IconData fallback;
  final double? size;
  final Color? color;
  final FontWeight weight;
  final String? semanticLabel;

  const SfSymbolIcon(
    this.name, {
    super.key,
    required this.fallback,
    this.size,
    this.color,
    this.weight = FontWeight.w600,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;

    if (!kIsWeb && Platform.isIOS) {
      return Semantics(
        label: semanticLabel,
        child: SfSymbol(
          name: name,
          size: resolvedSize,
          color: resolvedColor,
          weight: weight,
        ),
      );
    }

    return Icon(
      fallback,
      size: resolvedSize,
      color: resolvedColor,
      semanticLabel: semanticLabel,
    );
  }
}
