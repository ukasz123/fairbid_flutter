part of 'internal.dart';

/// Allows for passing user GDPR consent information.
class GDPR {
  GDPR._();

  /// Update GDPR consent data
  ///
  /// The [consentString] should be a correct string formatted according to [IAB specification](https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/Consent%20string%20and%20vendor%20list%20formats%20v1.1%20Final.md)
  ///
  static Future<void> updateConsent(
      {@required bool grantsConsent, String consentString}) {
    assert(grantsConsent != null);
    final params = <String, Object>{
      "grantConsent": grantsConsent,
      if (consentString != null) "consentString": consentString,
    };
    return FairBidInternal._channel.invokeMethod("updateGDPR", params);
  }

  /// Clears all GDPR related data
  static Future<void> clearConsent() =>
      FairBidInternal._channel.invokeMethod("clearGDPR");
}
