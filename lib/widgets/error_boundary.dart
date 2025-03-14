import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.onRetry,
    this.onError,
  }) : super(key: key);

  /// Static helper to wrap a widget with proper error handling
  static Widget wrap({required Widget child, VoidCallback? onRetry}) {
    return ErrorBoundary(child: child, onRetry: onRetry);
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Error? _error;
  StackTrace? _stackTrace;
  final AppLogger _logger = AppLogger();
  bool _hasError = false;

  // Flag to prevent recursive error handling
  bool _handlingError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Any setup that depends on inherited widgets should go here
  }

  @override
  Widget build(BuildContext context) {
    // Short-circuit if we have an error already
    if (_hasError) {
      return _buildErrorUI();
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      if (!_handlingError) {
        _handlingError = true;
        _handleError(error, stackTrace);
        _handlingError = false;
      }
      return _buildErrorUI();
    }
  }

  // Simplified error UI with proper widget hierarchy
  Widget _buildErrorUI() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        // Use Material to get theme-based UI
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (widget.onRetry != null)
                ElevatedButton(
                  onPressed: _resetErrorState,
                  child: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetErrorState() {
    setState(() {
      _error = null;
      _stackTrace = null;
      _hasError = false;
    });
    if (widget.onRetry != null) {
      widget.onRetry!();
    }
  }

  void _handleError(dynamic error, StackTrace? stackTrace) {
    _logger.error("Error caught in boundary",
        error: error, stackTrace: stackTrace);

    // Only update state if not already in error state
    if (!_hasError && mounted) {
      setState(() {
        _error = error is Error ? error : Error();
        _stackTrace = stackTrace;
        _hasError = true;
      });
    }

    // Forward to custom error handler if provided
    if (widget.onError != null) {
      widget.onError!(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'error_boundary',
        context: ErrorDescription('Error caught by ErrorBoundary'),
      ));
    }
  }
}
