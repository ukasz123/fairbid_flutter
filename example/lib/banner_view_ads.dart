import 'package:fairbid_flutter/fairbid_flutter.dart';
import 'package:flutter/material.dart';

class BannerViewAds extends StatefulWidget {
  final FairBid sdk;

  const BannerViewAds({Key? key, required this.sdk}) : super(key: key);
  @override
  _BannerViewAdsState createState() => _BannerViewAdsState();
}

class _BannerViewAdsState extends State<BannerViewAds> {
  List<String> _placements = [];

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
                    _placements.add(_placementController.text);
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
      ]..addAll(
          _placements.map(
            (placement) => Dismissible(
              key: ValueKey(placement),
              onDismissed: (_) => setState(() => _placements.remove(placement)),
              child: Column(
                children: [
                  FittedBox(child: Text(placement)),
                  Container(
                    alignment: Alignment.center,
                    color: Color.fromARGB(124, 100, 200, 0),
                    child: BannerView(
                      placement,
                      widget.sdk,
                      errorWidgetBuilder: (c, error) =>
                          Center(child: Text("$error")),
                      placeholderBuilder: (c) => Placeholder(),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  )
                ],
              ),
            ),
          ),
        ),
    );
  }
}
