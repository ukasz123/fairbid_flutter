import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:flutter/material.dart';

class GDPRControls extends StatelessWidget {
  const GDPRControls({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      alignment: WrapAlignment.center,
      children: <Widget>[
        OutlineButton(
          onPressed: () async {
            await PrivacySettings.updateGDPRConsent(
                grantsConsent: true,
                consentString: "IABCompliantConstentString");
            print("GDPR consent granted");
          },
          child: Text("Grant GDPR consent"),
        ),
        OutlineButton(
          onPressed: () async {
            await PrivacySettings.updateGDPRConsent(grantsConsent: false);
            print("GDPR consent revoked");
          },
          child: Text("Revoke GDPR consent"),
        ),
        OutlineButton(
          onPressed: () async {
            await PrivacySettings.updateCCPAString(
                ccpaString: "IABCompliantConstentString");
            print("CCPA String updated");
          },
          child: Text("Grant GDPR consent"),
        ),
        OutlineButton(
          onPressed: () async {
            await PrivacySettings.clear();
            print("Privacy settings cleared");
          },
          child: Text("Clear privacy settings"),
        ),
      ],
    );
  }
}
