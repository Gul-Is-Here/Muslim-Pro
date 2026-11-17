import 'package:flutter/material.dart';
import 'package:get/get.dart';

final class ErrorRetry extends StatelessWidget {
  const ErrorRetry({required this.messageKey, required this.onRetry, super.key});

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(messageKey.tr, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
        ],
      ),
    ),
  );
}
