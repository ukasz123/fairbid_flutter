import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fairbid_flutter/fairbid_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FairBid _sdk;

  StreamSubscription<String> _sub;
  List<String> _placements = [];

  TextEditingController _placementIdController;

  Map<String, Widget> bannersCache = {};

  //TODO update me
  String get _appId => null;

  @override
  void initState() {
    _placementIdController = TextEditingController();
    _sdk = FairBid.forOptions(
        Options(appId: _appId));
    _sub = _sdk.events
        .map((event) => '${event.eventType}: ${event.payload}')
        .listen((event) {
      print(event);
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
          FutureBuilder<bool>(
              future: _sdk.started,
              builder: (context, snapshot) => CheckboxListTile(
                  title: GestureDetector(child: Text('Started'), onTap: (){
                    _sdk.showTestSuite();
                  }),
                  value: snapshot.data ?? false,
                  onChanged: null)),
          Divider(),
          ListTile(
              title: TextFormField(
                controller: _placementIdController,
                keyboardType: TextInputType.number,
              ),
              trailing: IconButton(
                  icon: Icon(Icons.thumb_up), onPressed: _addPlacement)),
          Divider(),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
                itemCount: _placements.length*5,
                itemBuilder: (context, index) {
                  var modulo = index % 5;
                  if (modulo == 0){
                  var realIndex = (index/5).floor();
                  var placement = _placements[realIndex];
                  return Dismissible(child: _bannerContainer(placement), key: ValueKey('$placement$realIndex',), onDismissed: (_){
                    setState(() {
                      _placements.removeAt(realIndex);
                    });
                  },);
                  } else {
                    return Container(height: 68, color: Color.fromARGB(0xff, 0xaa&(index*17), (index*13) % 255, 0xff&(index * 19)),);
                  }
                }),
          )
        ]),
      ),
    );
  }

  void _addPlacement() {
    var placementId = _placementIdController.value.text;
    _placements.insert(0, placementId);
    _placementIdController.clear();
    setState(() {});
  }

  Widget _bannerContainer(String placement) {
    Widget banner = bannersCache[placement];
    if (banner == null) {
      banner = BannerContainer(_sdk, name: placement, id: placement);
      bannersCache[placement] = banner;
    }
    return banner;
  }
}

class BannerContainer extends StatelessWidget {
  final FairBid _sdk;
  final String name;
  final String id;

  Widget _errorBuilder(context, error) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text('Error:\n$error'),
  );
  Widget _placeholderBuilder(context) => SizedBox(
        height: 45,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: LinearProgressIndicator()),
        ),
      );

  BannerContainer(this._sdk, {@required this.name, @required String id})
      : this.id = id,
        super(key: ValueKey(id));
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('$name ($id)'),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          color: Color(0xffa4a4a4 & name.hashCode),
          alignment: Alignment.center,
          child: BannerView.banner(
            id,
            _sdk,
            errorWidgetBuilder: _errorBuilder,
            placeholderBuilder: _placeholderBuilder,
          ),
        ),
      ],
    );
  }
}
