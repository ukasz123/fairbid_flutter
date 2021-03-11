/// Plugin for FairBid SDK from Fyber
///
/// See [FairBid SDK official documentation](https://developer.fyber.com/hc/en-us/categories/360001778457-Fyber-FairBid).
///
/// Starting point is a [FairBid] class which is used to initialize the native SDK
library fairbid_flutter;

import 'src/internal.dart';
export 'src/banner_view.dart' show BannerView;
// export 'src/banner_view_talisman.dart' show BannerView;
export 'src/internal.dart'
    show
        Options,
        LoggingLevel,
        AdEvent,
        AdType,
        InterstitialAd,
        RewardedAd,
        AdEventType,
        PrivacySettings,
        UserData,
        Gender,
        Location,
        BannerAd,
        BannerAlignment,
        ImpressionData;

/// Starting point for interacting with FairBid native SDK.
///
/// You MUST create instance of [FairBid] before any other interaction with library, even when using [BannerView]s.
class FairBid {
  final FairBidInternal _delegate;

  /// Prepares FairBid SDK for running with provided [Options].
  static FairBid forOptions(Options options) {
    FairBid instance = FairBid._(options);
    return instance;
  }

  FairBid._(Options options)
      : _delegate = FairBidInternal.forOptions(options);

  /// Returns a [Future] that completes to the version of integrated FairBid SDK.
  static Future<String> get version => FairBidInternal.platformVersion;

  /// Returns a [Future] that completes to `true` when native SDK has been started.
  Future<bool> get started => _delegate.started;

  /// Stream of [AdEvent]s for all ads combined
  Stream<AdEvent> get events => _delegate.events;

  /// Opens FairBid's Test Suite native view.
  ///
  /// The Test Suite is a tool provided in the SDK that allows for checking
  /// the state of integration of mediated ad networks.
  void showTestSuite() => _delegate.showTestSuite();

  /// Prepares [InterstitialAd] instance for requesting and showing interstitial ad
  InterstitialAd prepareInterstitial(String placementId) =>
      _delegate.prepareInterstitial(placementId);

  /// Prepares [RewardedAd] instance for requesting and showing rewarded ad
  RewardedAd prepareRewarded(String placementId) =>
      _delegate.prepareRewarded(placementId);

  /// Prepares [BannerAd] instance for showing and destroying banner ad
  BannerAd prepareBanner(String placementId) =>
      _delegate.prepareBanner(placementId);

  /// Sets a flag for some mediated networks to show video ads with audio muted or not
  static Future<void> setMuted(bool muteAds) =>
      FairBidInternal.setMuted(muteAds);
}
