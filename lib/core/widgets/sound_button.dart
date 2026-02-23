import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/audio/presentation/audio_provider.dart';

/// Tıklandığında ses çalan buton widget'ı
class SoundButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const SoundButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        ref.read(audioProvider.notifier).playClick();
        onPressed();
      },
      icon: child,
      style: style,
    );
  }
}

/// Tıklandığında ses çalan ElevatedButton
class SoundElevatedButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const SoundElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: onPressed != null
          ? () {
              ref.read(audioProvider.notifier).playClick();
              onPressed!();
            }
          : null,
      style: style,
      child: child,
    );
  }
}

/// Tıklandığında ses çalan TextButton
class SoundTextButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const SoundTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: onPressed != null
          ? () {
              ref.read(audioProvider.notifier).playClick();
              onPressed!();
            }
          : null,
      style: style,
      child: child,
    );
  }
}

/// Hover ve tıklama sesi olan InkWell wrapper
class SoundInkWell extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  const SoundInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  ConsumerState<SoundInkWell> createState() => _SoundInkWellState();
}

class _SoundInkWellState extends ConsumerState<SoundInkWell> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap != null
          ? () {
              ref.read(audioProvider.notifier).playClick();
              widget.onTap!();
            }
          : null,
      onHover: (isHovering) {
        if (isHovering) {
          ref.read(audioProvider.notifier).playHover();
        }
      },
      borderRadius: widget.borderRadius,
      child: widget.child,
    );
  }
}

/// ListTile tıklandığında ses çalması için wrapper
class SoundListTile extends ConsumerWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const SoundListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      contentPadding: contentPadding,
      onTap: onTap != null
          ? () {
              ref.read(audioProvider.notifier).playClick();
              onTap!();
            }
          : null,
    );
  }
}
