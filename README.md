# fairbid_flutter
Unofficial plugin for [FairBid SDK](https://www.fyber.com/fyber-fairbid/) from Fyber - the advertisement mediation platform. Supports banner, interstitial and rewarded video ads.

## Getting Started

Before you start you need to be at least familiar with [FairBid SDK official documentation](https://developer.fyber.com/hc/en-us/categories/360001778457-Fyber-FairBid). Topics you should be familiar with:
- [publisher's console](https://developer.fyber.com/hc/en-us/sections/360002888297-Getting-Started-with-FairBid) - to configure apps and prepare ad placements
- [mediation networks integration](https://developer.fyber.com/hc/en-us/sections/360002896737-FairBid-Mediation) - to learn how to setup your Android/iOS projects to provide additional mediation platforms
- ad types provided by FairBid SDK - to know what suits your needs and how to use different ad types

## SDK setup
Create account [Publishers UI](https://console.fyber.com/sign-up) and create configurations for Android and/or iOS app. App Ids has to be used to initialize SDK as described on official documentation for [Android](https://developer.fyber.com/hc/en-us/articles/360010079697-Initialize-the-SDK) and [iOS](https://developer.fyber.com/hc/en-us/articles/360009930737-Initializing-the-SDK). You need to pass App Id for the platform your app is running on.
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

---

### Donate 

You can show that you appreciate my work by sending a donation.

[![Donate with PayPal](https://www.paypalobjects.com/en_US/PL/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZD8WFEWA7KEPQ&source=url)
