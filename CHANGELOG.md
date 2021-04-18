### 1.0.1
* Updated dependencies to **FairBid 3.14.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
  * Deprecated `PrivacySettings.clearGDPRConsent()`

### 1.0.0
* **Breaking change:** `Null-safety` support
* Updated dependencies to **FairBid 3.13.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))

### 0.11.2
* Updated dependencies to **FairBid 3.12.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
* Fixed [crash on iOS](https://github.com/ukasz123/fairbid_flutter/pull/21) when attempting to show full screen ads.

### 0.11.1
* Added new parameter for starting `Option` to give fine grained control over SDK's logging on iOS.

### 0.11.0
* Updated dependencies to **FairBid 3.11.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
* **New API:** `InterstitialAd` and `RewardedAd` have new getter `impressionData` for getting impression data for current fill
* **New API:** `ImpressionData` has new property `variantId` - in case using multi test experiment on placement it contains the id of the test variant
* **New API:** `InterstitialAd` has new method `showWithSSR` to pass some parameters to server rewarding endpoint being called by FairBid backend.

### 0.10.0
* Updated dependencies to **FairBid 3.10.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
  * Added support for for **Ogury** Interstitials, Rewarded and Banner ads
  * Added support for Vungle banners

### 0.9.0
* Updated dependencies to **FairBid 3.8.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
* Add new `changeAutoRequesting` method to full screen ads (Official documentation: [Android](https://developer.fyber.com/hc/en-us/articles/360010251798-Auto-Request#auto-request-configuration-per-placement-0-2), [iOS](https://developer.fyber.com/hc/en-us/articles/360009940017-Auto-Request#auto-request-configuration-per-placement-0-2))
  * It allows for more precise control over how often placements are requested.

### 0.8.2
* Fix issue for Android banners - some banners may not be shown until they were properly measured
  * The implementation enforces the same sizing rules as FairBid SDK does
* Add missing InMobi dependencies to examples

### 0.8.1
* Updated dependencies to **FairBid 3.7.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog))
* [InMobi SDK|https://www.inmobi.com] support

### 0.8.1-dev.1
* Banners on Android should not always take whole available space

### 0.8.0
* Updated dependencies to **FairBid 3.6.0** (Official changelog: [Android](https://developer.fyber.com/hc/en-us/articles/360010205178-FairBid-Android-SDK-Changelog#version-3-6-0-0-0), [iOS](https://developer.fyber.com/hc/en-us/articles/360010021878-FairBid-iOS-SDK-Changelog#version-3-6-0-0-0))
* Implementation of `setMuted` method - used to force audio to be turned off when ad is shown
  * This setting is passed to mediated networks that support this feature
* Documentation links update - all links to official FairBid documentation should use the new website
* Updated Android example 

### 0.8.0-dev.5
* Update dependencies to **FairBid 3.5.0** (Official changelog: [Android](https://dev-android.fyber.com/docs/fairbid-sdk#version-350), [iOS](https://dev-ios.fyber.com/docs/fairbid-sdk#version-350))
  * AdColony banner support
  * Improved auto-request behaviour
* iOS plugin implementation updated to support Flutter SDK 1.20

### 0.8.0-dev.4
* Update dependencies to **FairBid 3.4.1** (Official changelog: [Android](https://dev-android.fyber.com/docs/fairbid-sdk#version-341), [iOS](https://dev-ios.fyber.com/docs/fairbid-sdk#version-341))
* Changed BannerView API:
  * removed unsupported `rectangle` version

### 0.8.0-dev.3
* Update dependencies to **FairBid 3.3.0** (Official changelog: [Android](https://dev-android.fyber.com/docs/fairbid-sdk#version-330), [iOS](https://dev-ios.fyber.com/docs/fairbid-sdk#version-330))

### 0.8.0-dev.2
* Update dependencies to **FairBid 3.2.1** (Official changelog: [iOS only](https://dev-ios.fyber.com/docs/fairbid-sdk#version-321))

### 0.8.0-dev.1
* Native BannerView has been rewritten
  * Added dependency to RxDart
  * Example app for testing native banners has been provided

### 0.7.0 (SDK 3.2.0)
* Update dependencies to **FairBid 3.2.0** (Official changelog: [Android](https://dev-android.fyber.com/docs/fairbid-sdk), [iOS](https://dev-ios.fyber.com/docs/fairbid-sdk)),
    * **[Breaking change]** Add required `compileOptions` section to Android build scripts
    * **[Breaking change]** Update iOS project to Xcode 11.4
### 0.6.0 (SDK 2.6.0)
* Update dependencies to **FairBid 2.6.0** (Official changelog: [Android](https://dev-android.fyber.com/docs/fairbid-sdk), [iOS](https://dev-ios.fyber.com/docs/fairbid-sdk));
* Breaking API changes:
    * `GDPR` class was renamed to `PrivacySettings`,
    * `updateConsent` was renamed to `updateGDPRConsent` (to reflect scope),
    * `clearConsent` was renamed to `clearGDPRConsent`;
* [CCPA](https://dev-android.fyber.com/docs/ccpa-consent-settings) compliant IAB US privacy string API.

### 0.5.2 (SDK 2.5.0)
* Fix file name issue for Android

### 0.5.1 (SDK 2.5.0)
* Improve description
* Improve code quality

### 0.5.0 (SDK 2.5.0)
* Support for FairBid SDK 2.5.0
