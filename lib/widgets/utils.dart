import 'package:flutter/material.dart';

/// Wrapper for showing a snackbar of a possible error when running [action].
void errorWrapper(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    debugPrint('$e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}
