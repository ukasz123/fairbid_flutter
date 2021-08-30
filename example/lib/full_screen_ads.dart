import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:fairbid_flutter_example/events_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class FullScreenAds extends StatefulWidget {
  final FairBid sdk;

  const FullScreenAds({Key? key, required this.sdk}) : super(key: key);

  @override
  _FullScreenAdsState createState() => _FullScreenAdsState();
}

class _FullScreenAdsState extends State<FullScreenAds> {
  late TextEditingController _placementController;

  late List<_AdWrapper> _placements;

  @override
  void initState() {
    super.initState();
    _placements = [];
    _placementController = TextEditingController();
  }

  @override
  void dispose() {
    _placementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _placementController,
                  decoration: InputDecoration(labelText: "Placement"),
                  keyboardType: TextInputType.number,
                ),
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: "Add Interstitial",
                    onPressed: _addInterstitial,
                    icon: Icon(Icons.fullscreen),
                    iconSize: 36,
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  IconButton(
                    tooltip: "Add Rewarded",
                    onPressed: _addRewarded,
                    icon: Icon(Icons.monetization_on),
                    iconSize: 36,
                  ),
                ],
              )
            ],
          ),
          Divider(),
          ListView.builder(
            shrinkWrap: true,
            primary: false,
            itemBuilder: (context, index) => _buildListItem(context, _placements[index]),
            itemCount: _placements.length,
          ),
        ],
      ),
    );
  }

  void _addInterstitial() {
    if (_placementController.text.trim().isNotEmpty) {
      var placement = _placementController.text.trim();
      InterstitialAd interstitialAd = widget.sdk.prepareInterstitial(placement);
      setState(() {
        _placements.add(InterstitialWrapper(placement, interstitialAd));
        _placementController.clear();
      });
    }
  }

  void _addRewarded() {
    if (_placementController.text.trim().isNotEmpty) {
      var placement = _placementController.text.trim();
      RewardedAd rewardedAd = widget.sdk.prepareRewarded(placement);
      setState(() {
        _placements.add(RewardedWrapper(placement, rewardedAd));
        _placementController.clear();
      });
    }
  }

  Widget _buildListItem(BuildContext context, _AdWrapper wrapper) {
    var isRewarded = wrapper is RewardedWrapper;
    AsyncCallback request, show;
    ValueUpdateMaybe<bool> autoRequestingChange;

    Stream<bool> available;
    Stream<AdEventType> events;
    AsyncValueGetter<ImpressionData?> impressionDataGetter;
    if (isRewarded) {
      RewardedAd rewardedAd = (wrapper as RewardedWrapper).ad;
      request = () => rewardedAd.request();
      show = () => rewardedAd.showWithSSR(serverSideRewardingOptions: {"option1": "value1"});
      available = rewardedAd.isAvailable.asStream().concatWith([rewardedAd.availabilityStream]);
      events = rewardedAd.simpleEvents;
      autoRequestingChange = rewardedAd.changeAutoRequesting;
      impressionDataGetter = () => rewardedAd.impressionData;
    } else {
      InterstitialAd interstitialAd = (wrapper as InterstitialWrapper).ad;
      request = () => interstitialAd.request();
      show = () => interstitialAd.showWithSSR(serverSideRewardingOptions: {"option1": "value1"});
      available =
          interstitialAd.isAvailable.asStream().concatWith([interstitialAd.availabilityStream]);
      events = interstitialAd.simpleEvents;
      autoRequestingChange = interstitialAd.changeAutoRequesting;
      impressionDataGetter = () => interstitialAd.impressionData;
    }
    return Dismissible(
      key: ValueKey(wrapper.name),
      onDismissed: (_) => setState(() {
        _placements.remove(wrapper);
      }),
      child: ListTile(
        onLongPress: () async {
          var d = await impressionDataGetter.call();
          print('Current impression data for ${wrapper.name} = $d');
        },
        onTap: () => showEventsStream(context: context, events: events, placement: wrapper.name),
        title: Row(
          children: <Widget>[
            Icon(
              isRewarded ? Icons.monetization_on : Icons.fullscreen,
              size: 16,
            ),
            SizedBox(
              width: 4,
            ),
            Expanded(child: FittedBox(child: Text(wrapper.name))),
          ],
        ),
        trailing: AdActions(
          showAvailable: available,
          showAction: show,
          requestAction: request,
          toggleAutoRequesting: autoRequestingChange,
        ),
      ),
    );
  }
}

typedef Future<T> ValueUpdateMaybe<T>(T value);

class AdActions extends StatefulWidget {
  final AsyncCallback requestAction;
  final AsyncCallback showAction;
  final Stream<bool>? showAvailable;
  final ValueUpdateMaybe<bool>? toggleAutoRequesting;

  const AdActions(
      {Key? key,
      required this.requestAction,
      required this.showAction,
      this.showAvailable,
      this.toggleAutoRequesting})
      : super(key: key);

  @override
  _AdActionsState createState() => _AdActionsState();
}

class _AdActionsState extends State<AdActions> {
  bool autoRequestEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        IconButton(
          tooltip: 'Request ad',
          onPressed: widget.requestAction,
          icon: Icon(Icons.file_download),
        ),
        StreamBuilder<bool>(
            stream: widget.showAvailable,
            builder: (context, snapshot) {
              var available = snapshot.hasData && snapshot.data!;
              return IconButton(
                tooltip: 'Show ad',
                disabledColor: Theme.of(context).iconTheme.color!.withOpacity(0.1),
                onPressed: available ? widget.showAction : null,
                icon: Icon(Icons.slideshow),
              );
            }),
        Switch.adaptive(
          onChanged: (value) async {
            var result = await widget.toggleAutoRequesting!(value);
            setState(() {
              autoRequestEnabled = result;
            });
          },
          value: autoRequestEnabled,
        )
      ],
    );
  }
}

abstract class _AdWrapper {
  final String name;

  _AdWrapper(this.name);
}

class InterstitialWrapper extends _AdWrapper {
  final InterstitialAd ad;

  InterstitialWrapper(String name, this.ad) : super(name);
}

class RewardedWrapper extends _AdWrapper {
  final RewardedAd ad;

  RewardedWrapper(String name, this.ad) : super(name);
}
