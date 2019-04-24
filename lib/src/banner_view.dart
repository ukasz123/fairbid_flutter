import 'dart:async';
import 'dart:io';

import 'package:fairbid_flutter/src/internal.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

// shared channel
const MethodChannel _channel = FairBidInternal.methodCallChannel;

const EventChannel _metadataChannel = EventChannel("pl.ukaszapps.fairbid_flutter:bannerMetadata");

const int _defaultBannerHeight = 50;

/// ⚠️This is an **experimental feature**. Use with caution as it may lead to fraud-like behavior of the app.
@experimental
class BannerView extends StatelessWidget {
  final String placement;

  const BannerView({Key key, this.placement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // we need to tell native code what size of banners it can fit into the view
      final viewConstraints = <String, int>{};
      if (constraints.hasBoundedHeight) {
        viewConstraints["height"] = constraints.biggest.height.floor();
      } else {
        viewConstraints["height"] = _defaultBannerHeight;
      }
      if (constraints.hasBoundedWidth) {
        viewConstraints["width"] = constraints.biggest.width.floor();
      } else {
        viewConstraints["width"] = constraints.maxWidth.floor();
      }
      final orientation = MediaQuery.of(context).orientation;
      return _NativeBannerWrapper(
        orientation: orientation,
        placement: placement,
        viewConstraints: viewConstraints,
      );
    });
  }
}

class _NativeBannerWrapper extends StatefulWidget {
  final String placement;

  final Map<String, int> viewConstraints;

  final Orientation orientation;

  const _NativeBannerWrapper({Key key, this.placement, this.viewConstraints, this.orientation})
      : super(key: key);

  @override
  _FBBannerState createState() => _FBBannerState();
}

class _FBBannerState extends State<_NativeBannerWrapper> {
  static final _messageCodec = const StandardMessageCodec();
  static final _viewType = "bannerView";

  Future<List<double>> _loadFuture;

  Stream<List<double>> _sizeStream;

  Map<String, dynamic> get bannerParams =>
      Map<String, dynamic>.from(widget.viewConstraints)
        ..putIfAbsent("placement", () => widget.placement);

  @override
  void initState() {
    super.initState();
    _loadFuture = _channel
        .invokeMethod<List<dynamic>>(
          "loadBanner",
          bannerParams,
        )
        .then((dynamicL) => dynamicL.cast<double>());
    _sizeStream = _metadataChannel.receiveBroadcastStream(widget.placement).map((data) => (data as List<dynamic>).cast<double>()).asBroadcastStream();
    
  }

  @override
  void dispose() {
    _channel.invokeMethod("destroyBanner", <String, dynamic>{
      "placement": widget.placement,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          double width = snapshot.data[0] <= 0 ? double.infinity : snapshot.data[0];
          double height = snapshot.data[1];
          PlatformViewCreatedCallback callback =
              (id) => print("Banner view created: $id");
          Widget nativeView;
          if (Platform.isAndroid) {
            nativeView = AndroidView(
              onPlatformViewCreated: callback,
              viewType: _viewType,
              creationParams: bannerParams,
              creationParamsCodec: _messageCodec,
            );
          } else {
            nativeView = UiKitView(
              viewType: _viewType,
              creationParams: bannerParams,
              creationParamsCodec: _messageCodec,
              onPlatformViewCreated: callback,
            );
          }
          return StreamBuilder<List<double>>(
            stream: _sizeStream,
            initialData: [width, height],
            builder: (context, snapshot) {
              return SizedBox(
                width: snapshot.data[0],
                height: snapshot.data[1],
                child: nativeView,
              );
            }
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              "Error occured: ${snapshot.error}",
              style: TextStyle(
                color: Color.fromARGB(0xff, 0xaa, 0x55, 0x55),
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
