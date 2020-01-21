import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
part 'events.dart';

part 'options.dart';
part 'ad_wrapper.dart';
part 'privacy.dart';
part 'user_data.dart';

class FairBidInternal {
  static const MethodChannel _channel =
      const MethodChannel('pl.ukaszapps.fairbid_flutter');

  static const EventChannel _eventsChannel =
      const EventChannel("pl.ukaszapps.fairbid_flutter:events");

  static const MethodChannel methodCallChannel = _channel;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  factory FairBidInternal.forOptions(Options options) {
    final sdkHandler = FairBidInternal._();
    sdkHandler._start(options._toMap());
    return sdkHandler;
  }
  Future<bool> get started => _started.future;

  Stream<AdEvent> get events => Stream.fromFuture(_started.future)
      .asyncExpand((started) => started ? _eventsStream : Stream.empty());

  void showTestSuite() => _channel.invokeMethod("showTestSuite");

  // private API

  Completer<bool> _started;
  Stream _rawEventsStream;
  Stream<AdEvent> _eventsStream;

  FairBidInternal._() {
    this._started = Completer<bool>();
    this._started.future.then((started) {
      if (started) {
        this._rawEventsStream = _eventsChannel.receiveBroadcastStream();
        this._eventsStream =
            _convertRawEventsStream(_rawEventsStream).asBroadcastStream();
      }
    });
  }

  Future<bool> _start(Map<String, dynamic> arguments) async {
    _channel.invokeMethod("startSdk", arguments).then(
        (started) => _started.complete(started),
        onError: (e) => _started.completeError(e));
    return _started.future;
  }

  Future<bool> _available(AdType adType, String placement) {
    assert(adType != null);
    assert(placement != null && placement.isNotEmpty);
    if (!_started.isCompleted) {
      return Future.value(false);
    }
    return _channel.invokeMethod("isAvailable", <String, String>{
      "adType": _adTypeToName(adType),
      "placement": placement,
    });
  }

  Stream<AdEvent> _convertRawEventsStream(Stream rawEventsStream) =>
      rawEventsStream
          .cast<List>()
          .map(_readEventData)
          // filter out unsupported events
          .where((event) => event != null);

  AdEvent _readEventData(List eventData) {
    String adTypeName = eventData[0];
    String placement = eventData[1];
    String eventName = eventData[2];
    Map<String, dynamic> impressionDataRaw = (eventData[3] as Map)?.cast();
    AdEventType eventType = _eventTypeFromName(eventName);
    AdType adType = _adTypeFromName(adTypeName);
    if (eventType == null || adType == null) {
      return null;
    }
    ImpressionData impressionData = impressionDataRaw != null
        ? ImpressionData._fromMap(adType, impressionDataRaw)
        : null;
    List<dynamic> extras = eventData.length > 4 ? eventData.sublist(4) : null;
    return AdEvent._(adType, placement, eventType, impressionData, extras);
  }

  Future<void> _request(AdType type, String placement) async {
    if (!_started.isCompleted) {
      throw FairBidSDKNotStartedException();
    }
    await _channel.invokeMethod("request", <String, String>{
      "adType": _adTypeToName(type),
      "placement": placement,
    });
  }

  Future<void> _show(AdType type, String placement,
      {Map<String, String> extraOptions}) async {
    if (!_started.isCompleted) {
      throw FairBidSDKNotStartedException();
    }
    await _channel.invokeMethod("show", <String, Object>{
      "adType": _adTypeToName(type),
      "placement": placement,
      "extraOptions": extraOptions,
    });
  }

  static Future<int> _getImpressionDepth(AdType type) =>
      _channel.invokeMethod("getImpressionDepth", <String, Object>{
        "adType": _adTypeToName(type),
      });

  InterstitialAd prepareInterstitial(String placementId) =>
      InterstitialAd._(sdk: this, placement: placementId);

  RewardedAd prepareRewarded(String placement) =>
      RewardedAd._(sdk: this, placement: placement);

  BannerAd prepareBanner(String placement) =>
      BannerAd._(this, placementId: placement);
}

/// Interstitials are static or video ads presented before, during or after the user interacts with your app.
/// The user can view and then immediately dismiss them. This is a non-rewarded format for the user.
///
/// Official documentation: [iOS](https://dev-ios.fyber.com/docs/interstitial), [Android](https://dev-android.fyber.com/docs/interstitial).
class InterstitialAd extends _AdWrapper {
  InterstitialAd._({@required FairBidInternal sdk, @required String placement})
      : super._(sdk, AdType.interstitial, placement);

  /// Impression depth represents the amount of impressions of interstitial ads.
  static Future<int> get impressionDepth =>
      FairBidInternal._getImpressionDepth(AdType.interstitial);
}

/// Rewarded ads are an engaging ad format that shows a short video ad to the user and in exchange the user will earn a reward. The user must consent and watch the video completely through to the end in order to earn the reward.
///
/// Official documentation: [iOS](https://dev-ios.fyber.com/docs/rewarded-ads), [Android](https://dev-android.fyber.com/docs/rewarded-video).
class RewardedAd extends _AdWrapper {
  RewardedAd._({@required FairBidInternal sdk, @required String placement})
      : super._(sdk, AdType.rewarded, placement);

  Future<void> showWithSSR({Map<String, String> serverSideRewarding}) => _sdk
      ._show(AdType.rewarded, placementId, extraOptions: serverSideRewarding);

  /// Impression depth represents the amount of impressions of rewarded ads.
  static Future<int> get impressionDepth =>
      FairBidInternal._getImpressionDepth(AdType.rewarded);
}

/// Used for displaying banner ad near top and bottom edges of the screen
class BannerAd with _EventsProvider {
  final FairBidInternal _sdk;

  final String placementId;

  BannerAd._(this._sdk, {@required this.placementId});

  /// Loads and shows banner ad
  ///
  Future<void> show(
      {BannerAlignment alignment = BannerAlignment.bottom}) async {
    await FairBidInternal._channel
        .invokeMethod('showAlignedBanner', <String, String>{
      'placement': this.placementId,
      'alignment': alignment == BannerAlignment.top ? 'top' : 'bottom',
    });
  }

  /// Destroy banner instance
  Future<void> destroy() async {
    await FairBidInternal._channel
        .invokeMethod('destroyAlignedBanner', <String, String>{
      'placement': this.placementId,
    });
  }

  /// Impression depth represents the amount of impressions of banner ads.
  static Future<int> get impressionDepth =>
      FairBidInternal._getImpressionDepth(AdType.banner);

  @override
  AdType get _type => AdType.banner;
}

enum BannerAlignment {
  top,
  bottom,
}

class FairBidSDKNotStartedException implements Exception {
  FairBidSDKNotStartedException();

  @override
  String toString() {
    return "FairBid SDK has not been started";
  }
}
