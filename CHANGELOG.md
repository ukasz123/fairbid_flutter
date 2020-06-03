### 0.8.0-dev.1
* Native BannerView has been rewritten
** Added dependency to RxDart
** Example app for testing native banners has been provided

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
