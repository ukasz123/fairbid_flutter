part of 'internal.dart';

/// Options for starting the FairBid SDK
class Options {
  /// The Fyber App ID. Can be found in the App Management Dashboard.
  ///
  /// For more information visit [official guide](https://developer.fyber.com/hc/en-us/articles/360009974838-Adding-an-App-to-the-Console).
  final String appId;

  /// Turns on/off auto-requesting ads feature. Default: `true`.
  ///
  /// Official articles about auto-requesting feature: [iOS](https://developer.fyber.com/hc/en-us/articles/360009940017-Auto-Request), [Android](https://developer.fyber.com/hc/en-us/articles/360010251798-Auto-Request).
  final bool autoRequesting;

  /// Turns on/off debug logging of the SDK. Default: `false`.
  final bool debugLogging;

  /// Logging level of the SDK. Defaults to `silent`. It overrides `debugLogging` when provided.
  final LoggingLevel? loggingLevel;

  Options(
      {required this.appId,
      this.autoRequesting = true,
      this.debugLogging = false,
      this.loggingLevel})
      : assert(appId.isNotEmpty);

  Map<String, dynamic> _toMap() => {
        "publisherId": appId,
        "autoRequesting": autoRequesting,
        "logging": (loggingLevel != null &&
                (loggingLevel == LoggingLevel.verbose ||
                    loggingLevel == LoggingLevel.info) ||
            (loggingLevel == null && debugLogging)),
        "loggingLevel": loggingLevel?.index ??
            (debugLogging
                ? LoggingLevel.verbose.index
                : LoggingLevel.silent.index),
      };
}

enum LoggingLevel { verbose, info, error, silent }
