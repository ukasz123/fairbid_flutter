import 'package:fairbid_flutter/fairbid_flutter.dart' as fb;
import 'package:fairbid_flutter_example/events_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BannerAds extends StatefulWidget {
  final fb.FairBid sdk;

  const BannerAds({Key? key, required this.sdk}) : super(key: key);
  @override
  _BannerAdsState createState() => _BannerAdsState();
}

class _BannerAdsState extends State<BannerAds> {
  List<fb.BannerAd> _ads = [];

  late TextEditingController _placementController;

  @override
  void initState() {
    super.initState();
    _placementController = TextEditingController();
  }

  @override
  void dispose() {
    _placementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _placementController,
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(
              tooltip: "Add Banner",
              onPressed: () {
                setState(() {
                  if (_placementController.text.trim().isNotEmpty) {
                    _ads.add(
                        widget.sdk.prepareBanner(_placementController.text));
                    _placementController.clear();
                  }
                });
              },
              iconSize: 36,
              icon: Icon(Icons.add),
            ),
          ],
        ),
        Divider(),
        ..._ads.map((bannerAd) => Dismissible(
              key: ValueKey(bannerAd),
              onDismissed: (_) => setState(() => _ads.remove(bannerAd)),
              child: ListTile(
                onTap: () => showEventsStream(
                    context: context,
                    events: bannerAd.simpleEvents,
                    placement: bannerAd.placementId),
                title: Text(bannerAd.placementId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Show on top',
                      icon: Icon(Icons.border_top),
                      onPressed: () => _show(bannerAd, fb.BannerAlignment.top),
                    ),
                    IconButton(
                      tooltip: 'Show on bottom',
                      icon: Icon(Icons.border_bottom),
                      onPressed: () =>
                          _show(bannerAd, fb.BannerAlignment.bottom),
                    ),
                    IconButton(
                      tooltip: 'Destroy',
                      icon: Icon(Icons.delete),
                      onPressed: () => _destroy(bannerAd),
                    ),
                  ],
                ),
              ),
            ))
      ],
    );
  }

  Future<void> _show(fb.BannerAd bannerAd, fb.BannerAlignment alignment) async {
    await bannerAd.show(alignment: alignment);
  }

  Future<void> _destroy(fb.BannerAd bannerAd) async {
    await bannerAd.destroy();
  }
}
