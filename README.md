# fairbid_flutter
Unofficial plugin for [FairBid 2.x SDK](https://www.fyber.com/meet-the-new-fyber-fairbid/) from Fyber

## Getting Started

Before you start you need to be at least familiar with [FairBid SDK official documentation](https://developer.fyber.com/fairbid2/). Topics you should be familiar with:
- [publisher UI](https://ui.fyber.com/docs) - to configure apps and prepare ad placements
- [mediation networks integration](https://fyber-mediation.fyber.com/docs) - to learn how to setup your Android/iOS projects to provide additional mediation platforms
- ad types provided by FairBid SDK - to know what suits your needs and how to use different ad types

## SDK setup
Create account [Publishers UI](https://console.fyber.com/sign-up) and create configurations for Android and/or iOS app. App Ids has to be used to initialize SDK as described on official documentation for [Android](https://dev-android.fyber.com/docs/initialize-the-sdk) and [iOS](https://dev-ios.fyber.com/docs/initialize-the-sdk). You need to pass App Id for the platform your app is running on.
```dart
var appId = Platform.isAndroid ? _ANDROID_APP_ID : _IOS_APP_ID;
sdk = FairBid.forOptions(Options(
        appId: appId
      ));
```
You should keep reference to the FairBid instance to create ad placement holders.

## Full screen ads

1. Initialize ad holder with placement id for the correct platform.
```dart
var interstitialPlacementId = Platform.isAndroid ? _ANDROID_INTERSTITIAL_PLACEMENT_ID : _IOS_INTERSTITIAL_PLACEMENT_ID;
var interstitialAd = sdk.prepareInterstitial(interstitialPlacementId);

var rewardedPlacementId = Platform.isAndroid ? _ANDROID_REWARDED_PLACEMENT_ID : _IOS_REWARDED_PLACEMENT_ID;
var rewardedAd = sdk.prepareRewarded(rewardedPlacementId);
```
2. Request for a fill for an ad.
```dart
await ad.request();
```
> Please note that the completion of `request()` doesn't mean the ad is available but only that requesting process has been started.
3. Check if there is a fill available.

```dart
var adAvailable = await ad.isAvailable();
```

4. Show ad when fill is available.
```dart
await ad.show();
```

## Banner ads

1. Initialize ad holder with placement id for the correct platform.
```dart
var bannerPlacementId = Platform.isAndroid ? _ANDROID_BANNER_PLACEMENT_ID : _IOS_BANNER_PLACEMENT_ID;
var bannerAd = sdk.prepareBanner(bannerPlacementId);
```
2. Load and show banner on the screen.
```dart
await bannerAd.show(alignment: BannerAlignment.top);
```
> Banners would show immediately and refresh automatically when ready.
3. When banner should not be visible on the screen it should be destroyed.
```dart
await bannerAd.destroy();
```