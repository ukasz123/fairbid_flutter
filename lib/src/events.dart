part of 'internal.dart';

/// The [AdEvent] contains data of the placement event triggered by FairBid SDK.
///
/// Events are related to different callbacks that FairBid SDK accepts.
class AdEvent {
  /// The [AdType] of the placement the [AdEvent] is generated for.
  final AdType adType;

  /// The placement id
  final String placementId;

  /// The [AdEventType] of event.
  final AdEventType eventType;

  /// The [ImpressionData] associated with the event containing detailed information for impression.
  ///
  /// May be null.
  final ImpressionData? impressionData;

  /// _(Optional)_ Extra data related to the event.
  ///
  /// See description of [AdEventType]s for extra information.
  final List<dynamic>? payload;

  const AdEvent._(this.adType, this.placementId, this.eventType, this.impressionData,
      [this.payload])
      : assert(placementId != '');

  @override
  bool operator ==(dynamic other) {
    if (other == null) {
      return false;
    }
    if (other is AdEvent) {
      return this.adType == other.adType &&
          this.placementId == other.placementId &&
          this.eventType == other.eventType &&
          this.impressionData == other.impressionData &&
          this.payload == other.payload;
    }
    return false;
  }

  @override
  int get hashCode => (((adType.hashCode * 31) + eventType.hashCode) * 31) + placementId.hashCode;

  @override
  String toString() {
    return "AdEvent($eventType/$adType)[$placementId]${impressionData != null ? "\n$impressionData\n" : ""}${payload != null ? " ($payload)" : ""}";
  }
}

/// The [AdEventType] relates to different callbacks from FairBid SDK.
enum AdEventType {
  /// Ad for placement became available for showing.
  ///
  /// Triggered for [AdType.interstitial] and [AdType.rewarded] placements.
  available,

  /// Ad for placement is not available yet.
  ///
  /// Usually this may be caused by no-fill answer from mediated ad networks or network connection issues.
  ///
  /// Triggered for [AdType.interstitial] and [AdType.rewarded] placements.
  unavailable,

  /// Ad was hidden and is no longer visible.
  ///
  /// Triggered for [AdType.banner] placements.
  hide,

  /// Ad was clicked by the user.
  ///
  /// Triggered for placements of all [AdType]s.
  click,

  /// Ad was successfully loaded.
  ///
  /// Triggered for [AdType.banner] placements.
  load,

  /// Ad was successfully shown to the user.
  ///
  /// Triggered for placements of all [AdType]s.
  show,

  /// Ad was not shown to the user due some error.
  ///
  /// Triggered for [AdType.interstitial] and [AdType.rewarded] placements.
  showFailure,

  /// Rewarded ad was watched by the user.
  ///
  /// Triggered for [AdType.rewarded] placements only.
  /// The [AdEvent.payload] list contains a [bool] value at index 0 that reflects whether user should be rewarded for watching the ad.
  completion,

  /// An error occurred while loading a banner ad.
  ///
  /// Triggered for [AdType.banner] placements.
  error,

  /// Request for ad has been started.
  ///
  /// Triggered for placements of all [AdType]s.
  request,
}

AdEventType? _eventTypeFromName(String name) {
  try {
    return AdEventType.values
        .firstWhere((event) => event.toString().toLowerCase().contains(name.toLowerCase()));
  } on StateError {
    return null;
  }
}

/// Ad type of placement [AdEvent] is related to.
enum AdType { interstitial, rewarded, banner }

String _adTypeToName(AdType type) {
  return type.toString().split('.').last;
}

AdType? _adTypeFromName(String name) {
  try {
    return AdType.values
        .firstWhere((event) => event.toString().toLowerCase().contains(name.toLowerCase()));
  } on StateError {
    return null;
  }
}

mixin _EventsProvider {
  Stream<AdEvent>? _eventsStream;

  bool _filterEvents(AdEvent event) => event.adType == _type && event.placementId == placementId;

  @protected
  FairBidInternal get _sdk;
  @protected
  AdType get _type;
  @protected
  String get placementId;

  /// Stream of [AdEvent]s that are related only to the placement described by the instance of this class.
  Stream<AdEvent> get events {
    if (_eventsStream == null) {
      _eventsStream = _sdk.events.where(_filterEvents).asBroadcastStream();
    }
    return _eventsStream!;
  }

  /// Stream of [AdEventType]s that are related only to the placement described by the instance of this class.
  Stream<AdEventType> get simpleEvents =>
      this.events.map((event) => event.eventType).asBroadcastStream();
}

enum PriceAccuracy {
  /// When the netPayout is ‘0’.
  undisclosed,

  /// When Fyber’s estimation of the impression value is based on historical data from non-programmatic mediated network’s reporting APIs.
  predicted,

  ///  When netPayout is the exact and committed value of the impression, available when impressions are won by programmatic buyers.
  programmatic,
}

/// Detailed information for each impression.
///
/// Contains granular details to allow you to analyse and optimize both your ad monetization and user acquisition strategies.
///
/// Relevant only to [AdEventType.show] and [AdEventType.showFailure] events.
/// Official documentation: [iOS](https://developer.fyber.com/hc/en-us/articles/360009940417-Impression-Level-Data), [Android](https://developer.fyber.com/hc/en-us/articles/360010150517-Impression-Level-Data).
class ImpressionData {
  /// Accuracy of [netPayout] value.
  final PriceAccuracy priceAccuracy;

  /// Net payout for an impression. The value accuracy is returned in [priceAccuracy].
  /// The value is provided in units returned in [currency].
  final double netPayout;

  /// Currency of the payout.
  final String? currency;

  /// Demand Source name is the name of the buy-side / demand-side entity that purchased the impression.
  /// When mediated networks win an impression, you’ll see the mediated network’s name. When a DSP buying
  /// through the programmatic marketplace wins the impression, you’ll see the DSP’s name.
  final String? demandSource;

  /// Name of the SDK rendering the ad.
  final String? renderingSdk;

  /// Version of the SDK rendering the ad.
  final String? renderingSdkVersion;

  /// The mediated ad network’s original Placement/Zone/Location/Ad Unit ID that you created in their dashboard.
  /// For ads shown by the Fyber Marketplace the [networkInstanceId] is the Placement ID you created in the Fyber console.
  final String? networkInstanceId;

  /// Type of the impression’s placement.
  final AdType placementType;

  /// Country location of the ad impression (in ISO country code).
  final String? countryCode;

  /// An unique identifier for a specific impression.
  final String? impressionId;

  /// Advertiser’s domain when available. Used as an identifier for a set of campaigns for the same advertiser.
  final String? advertiserDomain;

  /// Creative ID when available. Used as an identifier for a specific creative of a certain campaign.
  /// This is particularly useful information when a certain creative is found to cause user experience issues.
  final String? creativeId;

  /// Campaign ID when available used as an identifier for a specific campaign of a certain advertiser.
  final String? campaignId;

  /// Impression depth represents the amount of impressions in a given session per ad format.
  final int impressionDepth;

  /// Waterfall variant Identifier. When running a multi test experiment, this ID will help you identify which variant was delivered on the device.
  final String? variantId;

  ImpressionData._({
    required this.priceAccuracy,
    required this.netPayout,
    required this.currency,
    required this.demandSource,
    required this.renderingSdk,
    required this.renderingSdkVersion,
    required this.networkInstanceId,
    required this.placementType,
    required this.countryCode,
    required this.impressionId,
    required this.advertiserDomain,
    required this.creativeId,
    required this.campaignId,
    required this.impressionDepth,
    required this.variantId,
  });

  factory ImpressionData._fromMap(AdType type, Map<String, dynamic> data) {
    var accuracyName = data['priceAccuracy'] as String;
    PriceAccuracy accuracy = PriceAccuracy.undisclosed;
    switch (accuracyName.toLowerCase()) {
      case "programmatic":
        accuracy = PriceAccuracy.programmatic;
        break;
      case "predicted":
        accuracy = PriceAccuracy.predicted;
        break;
    }
    return ImpressionData._(
      priceAccuracy: accuracy,
      netPayout: data['netPayout'] as double? ?? 0.0,
      advertiserDomain: data['advertiserDomain'],
      campaignId: data['campaignId'],
      currency: data['currency'],
      countryCode: data['countryCode'],
      creativeId: data['creativeId'],
      demandSource: data['demandSource'],
      impressionId: data['impressionId'],
      networkInstanceId: data['networkInstanceId'],
      placementType: type,
      renderingSdk: data['renderingSdk'],
      renderingSdkVersion: data['renderingSdkVersion'],
      impressionDepth: data['impressionDepth'] as int? ?? 0,
      variantId: data['variantId'] as String?,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other == null) {
      return false;
    }
    if (other is ImpressionData) {
      return this.impressionId == other.impressionId;
    }
    return false;
  }

  @override
  int get hashCode => impressionId.hashCode;

  @override
  String toString() {
    return "ImpressionData($impressionId): {$priceAccuracy, $netPayout, $currency, $advertiserDomain, $campaignId, $creativeId, $demandSource, $networkInstanceId, $renderingSdk, $renderingSdkVersion, $impressionDepth}";
  }
}
