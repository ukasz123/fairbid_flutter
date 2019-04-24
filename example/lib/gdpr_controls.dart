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
            await GDPR.updateConsent(grantsConsent: true, consentString: "IABCompliantConstentString");
            print("GDPR consent granted");
          },
          child: Text("Grant consent"),
        ),
        OutlineButton(
          onPressed: () async {
            await GDPR.updateConsent(grantsConsent: false);
            print("GDPR consent revoked");
          },
          child: Text("Revoke consent"),
        ),
        OutlineButton(
          onPressed: () async {
            await GDPR.clearConsent();
            print("GDPR consent cleared");
          },
          child: Text("Clear consent"),
        ),
      ],
    );
  }
}
