part of 'internal.dart';

/// The event sent when the adapter of mediated SDK start has been finished.
class MediationAdapterStartEvent {
  /// Flag indicating if the start was successful.
  ///
  /// `true` when adapter has started successfully
  final bool successful;

  /// Name of the mediated network.
  final String networkName;

  /// Version of the mediated network SDK.
  final String networkVersion;

  /// Reason of failure.
  ///
  /// Contains some extra details about the cause of mediated network adapter start failure;
  final String? errorMessage;

  MediationAdapterStartEvent._(this.successful, this.networkName,
      this.networkVersion, this.errorMessage);
}

Stream<MediationAdapterStartEvent> _convertRawAdaterEventsStream(
        Stream<dynamic> rawEventsStream) =>
    rawEventsStream.map((rawData) {
      final map = (rawData as Map).cast<String, String>();
      final name = map['name']!;
      final version = map['version']!;
      final message = map['message'];
      return MediationAdapterStartEvent._(
          message == null, name, version, message);
    });
