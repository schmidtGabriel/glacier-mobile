import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Utility class for showing toast notifications throughout the app
class ToastHelper {
  /// Shows a custom toast notification with specified type
  static void showCustom(
    BuildContext context, {
    required String title,
    String? description,
    required ToastificationType type,
    Duration? duration,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.show(
      context: context,
      title: Text(title),
      description: description != null ? Text(description) : null,
      type: type,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      alignment: alignment,
    );
  }

  /// Shows an error toast notification
  static void showError(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      description: description != null ? Text(description) : null,
      type: ToastificationType.error,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      alignment: alignment,
    );
  }

  /// Shows an info toast notification
  static void showInfo(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      description: description != null ? Text(description) : null,
      type: ToastificationType.info,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      alignment: alignment,
    );
  }

  /// Shows a success toast notification
  static void showSuccess(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      description: description != null ? Text(description) : null,
      type: ToastificationType.success,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      alignment: alignment,
    );
  }

  /// Shows a warning toast notification
  static void showWarning(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      description: description != null ? Text(description) : null,
      type: ToastificationType.warning,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      alignment: alignment,
    );
  }
}
