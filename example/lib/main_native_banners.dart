import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fairbid_flutter/fairbid_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FairBid _sdk;
  late StreamSubscription<String> _sub;
  List<String> _placements = [];
  TextEditingController? _placementIdController;
  Map<String, Widget> bannersCache = {};

  //TODO update me
  String get _appId => throw UnimplementedError('The app id has not been set');

  @override
  void initState() {
    _placementIdController = TextEditingController();
    _sdk = FairBid.forOptions(Options(appId: _appId));
    _sub = _sdk.events
        .map((event) => '${event.eventType}: ${event.payload}')
        .listen((event) {
      print(event);
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
          _buildTestSuiteTile(),
          Divider(),
          _buildNewPlacementTile(),
          Divider(),
          SizedBox(height: 8),
          _buildNativeBannerList()
        ]),
      ),
    );
  }

  Widget _buildTestSuiteTile() {
    return FutureBuilder<bool>(
      future: _sdk.started,
      builder: (context, snapshot) => CheckboxListTile(
        title: GestureDetector(
            child: Text('SDK Started - Tap for Test Suite'),
            onTap: () {
              _sdk.showTestSuite();
            }),
        value: snapshot.data ?? false,
        onChanged: null,
      ),
    );
  }

  Widget _buildNewPlacementTile() {
    return ListTile(
      title: TextFormField(
        decoration: const InputDecoration(labelText: 'New Placement ID:'),
        controller: _placementIdController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _addPlacement(),
      ),
      trailing: IconButton(
        icon: Icon(Icons.add_box),
        onPressed: _addPlacement,
      ),
    );
  }

  Widget _buildNativeBannerList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _placements.length * 5,
        itemBuilder: (context, index) {
          var modulo = index % 5;
          if (modulo == 0) {
            var realIndex = (index / 5).floor();
            var placementId = _placements[realIndex];
            return _buildNativeBannerListItem(placementId, realIndex);
          } else {
            return _buildColoredSpacerListItem(index);
          }
        },
      ),
    );
  }

  Widget _buildColoredSpacerListItem(int index) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Container(
        height: 68,
        color: Color.fromARGB(
          0xff,
          0xaa & (index * 17),
          (index * 13) % 255,
          0xff & (index * 19),
        ),
      ),
    );
  }

  Widget _buildNativeBannerListItem(String placementId, int realIndex) {
    return Dismissible(
      child: _buildBannerContainer(placementId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      key: ValueKey('$placementId$realIndex'),
      onDismissed: (_) {
        setState(() {
          _placements.removeAt(realIndex);
        });
      },
    );
  }

  Widget _buildBannerContainer(String placementId) {
    Widget? banner = bannersCache[placementId];
    if (banner == null) {
      banner = BannerContainer(_sdk, id: placementId);
      bannersCache[placementId] = banner;
    }
    return banner;
  }

  void _addPlacement() {
    final placementId = _placementIdController!.value.text;
    _placementIdController!.clear();
    _dismissKeyboard();
    setState(() {
      _placements.insert(0, placementId);
    });
  }

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.focusedChild?.unfocus();
    }
  }
}

class BannerContainer extends StatelessWidget {
  BannerContainer(this._sdk, {required String id})
      : this.id = id,
        super(key: ValueKey(id));

  final FairBid _sdk;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Placement $id'),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: BannerView(
            id,
            _sdk,
            errorWidgetBuilder: _errorBuilder,
            placeholderBuilder: _placeholderBuilder,
          ),
        ),
      ],
    );
  }

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
}
