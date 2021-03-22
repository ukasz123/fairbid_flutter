import 'package:fairbid_flutter_example/banner_view_ads.dart';
import 'package:fairbid_flutter_example/full_screen_ads.dart';
import 'package:fairbid_flutter_example/banner_ads.dart';
import 'package:fairbid_flutter_example/privacy_controls.dart';
import 'package:fairbid_flutter_example/user_data_form.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  print('Starting fairbid_flutter example');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _fairbidSdkVersion = 'Unknown';

  FairBid? _sdk;

  bool _enableLogs = true;

  bool _muteAds = false;

  late TextEditingController _sdkIdController;

  String? _appId;

  int _step = 0;

  bool get _sdkAvailable => _sdk != null;

  Stream<ImpressionData?>? _impressionStream;

  Stream<ImpressionData?>? get impressionsStream {
    if (_impressionStream == null) {
      _impressionStream = Stream.fromFuture(_sdk!.started)
          .asyncExpand((_) => _sdk!.events
              .where((event) => event.impressionData != null)
              .map((event) => event.impressionData))
          .asBroadcastStream();
    }
    return _impressionStream;
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _sdkIdController = TextEditingController();
  }

  @override
  void dispose() {
    _sdkIdController.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String fairbidSdkVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      fairbidSdkVersion = await FairBid.version;
    } on PlatformException {
      fairbidSdkVersion = 'Failed to get SDK version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _fairbidSdkVersion = fairbidSdkVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FairBid example app'),
        ),
        body: Builder(
          builder: (context) => Column(
            children: <Widget>[
              Text('Running on: $_fairbidSdkVersion\n'),
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _step,
                  onStepTapped: (step) => setState(() => _step = step),
                  controlsBuilder: (context,
                          {VoidCallback? onStepContinue, VoidCallback? onStepCancel}) =>
                      Container(),
                  steps: <Step>[
                    Step(
                      title: Text("Setup SDK"),
                      isActive: !_sdkAvailable,
                      subtitle: _appId == null ? null : Text("App ID: $_appId"),
                      content: _buildFirstStep(),
                    ),
                    Step(
                      title: Text("User data"),
                      isActive: _sdkAvailable,
                      subtitle: Text("Optional"),
                      content: _sdkAvailable ? UserDataForm() : Container(),
                    ),
                    Step(
                      isActive: _sdkAvailable,
                      title: Text("Ads control"),
                      subtitle: _sdkAvailable
                          ? ImpressionPresenter(
                              [AdType.interstitial, AdType.rewarded],
                              impressionsStream,
                              [InterstitialAd.impressionDepth, RewardedAd.impressionDepth])
                          : null,
                      content: _sdkAvailable ? _buildSdkWidgets(context) : Container(),
                    ),
                    Step(
                      isActive: _sdkAvailable,
                      title: Text("Banners control"),
                      subtitle: _sdkAvailable
                          ? ImpressionPresenter(
                              [AdType.banner], impressionsStream, [BannerAd.impressionDepth])
                          : null,
                      content: _sdkAvailable ? BannerAds(sdk: _sdk!) : Container(),
                    ),
                    Step(
                      isActive: _sdkAvailable,
                      title: Text("Banner views control"),
                      subtitle: Text(
                        "Experimental",
                        style: TextStyle(color: Colors.deepOrangeAccent),
                      ),
                      content: _sdkAvailable ? BannerViewAds(sdk: _sdk!) : Container(),
                    ),
                    Step(
                      isActive: _sdkAvailable,
                      title: Text("Test suite"),
                      content: OutlinedButton(
                        child: Text("Open Test suite"),
                        onPressed: () => _sdk?.showTestSuite(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstStep() => Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text("Enable debug logs"),
              ),
              Switch.adaptive(
                value: _enableLogs,
                onChanged: (enable) => setState(() => _enableLogs = enable),
              )
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.numberWithOptions(),
                  controller: _sdkIdController,
                  decoration: InputDecoration(hintText: "Publisher Id"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: OutlinedButton(
                  onPressed: () {
                    _initSDK();
                  },
                  child: Text("Start SDK"),
                ),
              ),
            ],
          ),
          GDPRControls(),
          Row(
            children: <Widget>[
              Expanded(
                child: Text("Mute ads"),
              ),
              Switch.adaptive(
                  value: _muteAds,
                  onChanged: (enable) async {
                    await FairBid.setMuted(enable);
                    setState(() => _muteAds = enable);
                  })
            ],
          ),
        ],
      );

  Widget _buildSdkWidgets(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sdk!.started,
      builder: (context, snapshot) => snapshot.hasData && snapshot.data!
          ? FullScreenAds(sdk: _sdk!)
          : Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }

  Future<void> _initSDK() async {
    var sdk = FairBid.forOptions(Options(
      appId: _sdkIdController.text.trim(),
      debugLogging: _enableLogs,
      loggingLevel: _enableLogs ? LoggingLevel.info : LoggingLevel.error,
    ));
    await sdk.started;
    setState(() {
      _sdk = sdk;
      _appId = _sdkIdController.text;
      // go to full screen ads
      _step = 2;
    });
  }
}

class ImpressionPresenter extends StatelessWidget {
  final List<AdType> adTypes;
  final Stream<ImpressionData?>? impressions;
  final List<Future<int?>> initialImpressions;

  const ImpressionPresenter(this.adTypes, this.impressions, this.initialImpressions, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var index = 0; index < adTypes.length; index++)
          StreamBuilder<int?>(
            initialData: 0,
            stream: Rx.concat([
              initialImpressions[index].asStream(),
              impressions!
                  .where((imp) => imp!.placementType == adTypes[index])
                  .map((imp) => imp!.impressionDepth)
            ]),
            builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
              return Chip(label: Text('${snapshot.data}'));
            },
          ),
      ],
    );
  }
}
