import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/core/utils/view_state.dart';

// Shared look of the sign-in, sign-up and reset screens.
const _ink = Color(0xFF131B2E);
const _muted = Color(0xFF404946);
const _fill = Color(0xFFF1F4F3);
const _deep = Color(0xFF002F2A);
const _gold = Color(0xFFFFDCC3);
const _sage = Color(0xFF9CD1C7);
const _jade = Color(0xFF4EDEA3);
const Color _accent = AppColors.amber800; // links: forgot password, sign in / up

TextStyle _label(Color color) =>
    TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.1);

/// Light page with a quiet top bar: back arrow only when there is somewhere to go back to.
final class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: _ink,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: child,
        ),
      ),
    ),
  );
}

/// Jewel tile with the compass-star motif (or [icon]), a mint halo and a gold spark.
final class AuthEmblem extends StatelessWidget {
  const AuthEmblem({this.icon, super.key});

  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 80,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [_sage.withValues(alpha: 0.55), _sage.withValues(alpha: 0)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryContainer, _deep],
            ),
            boxShadow: [
              BoxShadow(
                color: _deep.withValues(alpha: 0.22),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: icon == null
              ? const CustomPaint(size: Size.square(36), painter: _CompassStarPainter())
              : Icon(icon, size: 32, color: _jade),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            child: const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF2F1500)),
          ),
        ),
      ],
    ),
  );
}

/// Four-point star over a ring with tick marks, as on a compass rose.
final class _CompassStarPainter extends CustomPainter {
  const _CompassStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final star = Path()
      ..addPolygon([
        p(12, 2), p(14.8, 9.2), p(22, 12), p(14.8, 14.8), //
        p(12, 22), p(9.2, 14.8), p(2, 12), p(9.2, 9.2),
      ], true);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _jade;
    canvas
      ..drawPath(star, Paint()..color = _jade.withValues(alpha: 0.15))
      ..drawPath(star, line)
      ..drawCircle(p(12, 12), 3 * k, line..strokeWidth = 1.8 * k);
    line.strokeWidth = 1.6 * k;
    for (var i = 0; i < 4; i++) {
      final d = Offset.fromDirection(i * math.pi / 2);
      canvas.drawLine(p(12, 12) + d * 5 * k, p(12, 12) + d * 7 * k, line);
    }
  }

  @override
  bool shouldRepaint(_CompassStarPainter old) => false;
}

final class AuthHeading extends StatelessWidget {
  const AuthHeading({required this.title, required this.body, this.icon, super.key});

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuthEmblem(icon: icon),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          height: 1.3,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: _ink,
        ),
      ),
      const SizedBox(height: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.55, color: _muted),
        ),
      ),
    ],
  );
}

final class AuthCard extends StatelessWidget {
  const AuthCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

/// Label above a soft filled field with a leading icon.
final class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.obscure = false,
    this.onToggleObscure,
    this.onSubmitted,
    this.labelTrailing,
    this.fieldKey,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;

  /// When set, the field gets an eye button.
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;
  final Widget? labelTrailing;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _label(_muted))),
            ?labelTrailing,
          ],
        ),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscure,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: _ink, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: _fill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: Icon(icon, size: 20, color: _muted),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    tooltip: 'toggle_password'.tr,
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: _muted,
                    ),
                  ),
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            focusedBorder: border(AppColors.primaryContainer, 1.5),
            errorBorder: border(const Color(0xFFBA1A1A), 1),
            focusedErrorBorder: border(const Color(0xFFBA1A1A), 1.5),
          ),
        ),
      ],
    );
  }
}

/// Error or confirmation from the last request; announced by screen readers.
final class AuthStatus extends StatelessWidget {
  const AuthStatus({required this.state, super.key});

  final ViewState<String> state;

  @override
  Widget build(BuildContext context) {
    final (key, error) = switch (state) {
      ViewError(:final messageKey) => (messageKey, true),
      Success(:final data) => (data, false),
      _ => (null, false),
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: key == null
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: error ? const Color(0xFFFFDAD6) : AppColors.emerald50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(
                      error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: error ? const Color(0xFF93000A) : AppColors.emerald800,
                    ),
                    Expanded(
                      child: Text(
                        key.tr,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: error ? const Color(0xFF93000A) : AppColors.emerald800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

final class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    required this.busy,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.75),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 20),
              ],
            ),
    ),
  );
}

final class OrDivider extends StatelessWidget {
  const OrDivider(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF707977),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gray200)),
      ],
    ),
  );
}

/// Apple (dark) or Google (white, with the four-colour G).
final class ProviderButton extends StatelessWidget {
  const ProviderButton.apple({required this.label, required this.onPressed, super.key})
    : apple = true;

  const ProviderButton.google({required this.label, required this.onPressed, super.key})
    : apple = false;

  final String label;
  final VoidCallback? onPressed;
  final bool apple;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: Material(
      color: apple ? const Color(0xFF111111) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: apple ? 0 : 0.6,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              if (apple)
                const Icon(Icons.apple, size: 22, color: Colors.white)
              else
                const CustomPaint(size: Size.square(18), painter: _GoogleGPainter()),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: apple ? Colors.white : _ink,
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

/// Google's "G" from four arcs and the crossbar, so no image asset is needed.
final class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (s - stroke) / 2);
    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = c;
    const deg = math.pi / 180;
    canvas
      ..drawArc(rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335))) // red, top
      ..drawArc(rect, -140 * deg, -80 * deg, false, arc(const Color(0xFFFBBC05))) // yellow, left
      ..drawArc(rect, 140 * deg, -95 * deg, false, arc(const Color(0xFF34A853))) // green, bottom
      ..drawArc(rect, 45 * deg, -45 * deg, false, arc(const Color(0xFF4285F4))) // blue, right
      ..drawRect(
        Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
        Paint()..color = const Color(0xFF4285F4),
      );
  }

  @override
  bool shouldRepaint(_GoogleGPainter old) => false;
}

/// "Question? Action" line under the form.
final class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({
    required this.question,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(question, style: const TextStyle(fontSize: 14, color: _muted)),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Text(action),
      ),
    ],
  );
}

/// Small link-style button (forgot password, use another email).
final class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: _accent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    child: Text(label),
  );
}

/// What the account is for and what never leaves the phone.
final class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF5F3),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: Color(0xFFB7EDE3), shape: BoxShape.circle),
          child: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF00201C)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text('auth_privacy_title'.tr, style: _label(_ink)),
              Text(
                'auth_privacy_body'.tr,
                style: const TextStyle(fontSize: 12.5, height: 1.5, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
