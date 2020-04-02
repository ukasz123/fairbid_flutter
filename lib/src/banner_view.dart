import 'dart:async';
import 'dart:io';

import 'package:fairbid_flutter/src/internal.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../fairbid_flutter.dart';

// shared channel
const MethodChannel _channel = FairBidInternal.methodCallChannel;

const EventChannel _metadataChannel =
    EventChannel("pl.ukaszapps.fairbid_flutter:bannerMetadata");

enum _BannerType { BANNER, RECTANGLE }

typedef Widget ErrorWidgetBuilder(BuildContext context, Object error);

/// ⚠️This is an **experimental feature**. Use with caution as it may lead to fraud-like behavior of the app.
@experimental
class BannerView extends StatelessWidget {
  final String placement;
  final FairBid sdk;
  final _BannerType type;
  final WidgetBuilder placeholderBuilder;
  final ErrorWidgetBuilder errorWidgetBuilder;

  const BannerView._(
      {Key key,
      this.placement,
      this.sdk,
      this.placeholderBuilder,
      this.errorWidgetBuilder,
      this.type})
      : super(key: key);

  factory BannerView.rectangle(String placement, FairBid sdk,
          {WidgetBuilder placeholderBuilder,
          ErrorWidgetBuilder errorWidgetBuilder}) =>
      BannerView._(
        placement: placement,
        sdk: sdk,
        placeholderBuilder: placeholderBuilder,
        errorWidgetBuilder: errorWidgetBuilder,
        type: _BannerType.RECTANGLE,
      );

  factory BannerView.banner(String placement, FairBid sdk,
          {WidgetBuilder placeholderBuilder,
          ErrorWidgetBuilder errorWidgetBuilder}) =>
      BannerView._(
        placement: placement,
        sdk: sdk,
        placeholderBuilder: placeholderBuilder,
        errorWidgetBuilder: errorWidgetBuilder,
        type: _BannerType.BANNER,
      );

  @override
  Widget build(BuildContext context) {
    // height is fixed value depending on banner type
    double height = (type == _BannerType.BANNER ? 60 : 250);
    return LayoutBuilder(builder: (context, constraints) {
      final viewConstraints = <String, int>{};
      viewConstraints["height"] =
          (constraints.hasBoundedHeight ? constraints.maxHeight : height)
              .floor();

      // we need to tell native code what size of banners it can fit into the view

      if (constraints.hasBoundedWidth) {
        viewConstraints["width"] = constraints.biggest.width.floor();
      } else {
        viewConstraints["width"] = constraints.maxWidth.floor();
      }

      return _FBNativeBanner(
        placement: placement,
        sdk: sdk,
        viewConstraints: viewConstraints,
        errorWidgetBuilder: errorWidgetBuilder,
        placeholderBuilder: placeholderBuilder,
      );
    });
  }
}

class _FBNativeBanner extends StatefulWidget {
  final String placement;
  final FairBid sdk;

  final Map<String, int> viewConstraints;

  final WidgetBuilder placeholderBuilder;
  final ErrorWidgetBuilder errorWidgetBuilder;

  const _FBNativeBanner(
      {Key key,
      this.placement,
      this.sdk,
      this.viewConstraints,
      this.placeholderBuilder,
      this.errorWidgetBuilder})
      : super(key: key);

  @override
  _FBNativeBannerState createState() => _FBNativeBannerState();
}

class _FBNativeBannerState extends State<_FBNativeBanner> {
  static final _messageCodec = const StandardMessageCodec();
  static final _viewType = "bannerView";

  Future<dynamic> _loadFuture;

  Stream<List<double>> _sizeStream;

  Map<String, dynamic> get bannerParams =>
      Map<String, dynamic>.from(widget.viewConstraints)
        ..putIfAbsent("placement", () => widget.placement);

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.sdk.started.then((value) {
      if (value) {
        print('Loading banner: $bannerParams');
        return _channel.invokeMethod<dynamic>(
          "loadBanner",
          bannerParams,
        );
      } else {
        return Future.error('SDK not started properly');
      }
    });
    _sizeStream = _metadataChannel
        .receiveBroadcastStream(widget.placement)
        .map((data) => (data as List<dynamic>).cast<double>())
        .distinct((l, r) =>
            l.length == r.length &&
            l.asMap().entries.fold(true,
                (previousValue, element) => element.value == r[element.key]))
        .map((data) {
          print('Metadata incoming: $data');
          return data;
        })
        .where((data) => data[0] > 0.0 && data[1] > 0.0)
        .asBroadcastStream();
  }

  @override
  void dispose() {
        print('Destroying banner: $bannerParams');
    _channel.invokeMethod("destroyBanner", <String, dynamic>{
      "placement": widget.placement,
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print("Banner ${widget.placement} loaded: ${snapshot.data}");

          PlatformViewCreatedCallback callback =
              (id) => print("Banner ${widget.placement} view created: $id");
          Widget nativeView;
          if (Platform.isAndroid) {
            nativeView = AndroidView(key: ValueKey("FB_ban_${widget.placement}"),
              onPlatformViewCreated: callback,
              viewType: _viewType,
              creationParams: bannerParams,
              creationParamsCodec: _messageCodec,
            );
          } else {
            nativeView = UiKitView(key: ValueKey("FB_ban_${widget.placement}"),
              viewType: _viewType,
              creationParams: bannerParams,
              creationParamsCodec: _messageCodec,
              onPlatformViewCreated: callback,
            );
          }
          return StreamBuilder<List<double>>(
              stream: _sizeStream,
              initialData: [0, 0],
              builder: (context, snapshot) {
                print(
                    'Showing native view inside ${snapshot.data[0]}x${snapshot.data[1]} box');
                var size = Size(snapshot.data[0], snapshot.data[0]);
                if (size.isEmpty) {
                  return widget.placeholderBuilder != null? widget.placeholderBuilder(context) : Container();
                } else {
                  return Container(
                    width: snapshot.data[0],
                    height: snapshot.data[1],
                    child: nativeView,
                  );
                }
              });
        } else if (snapshot.hasError) {
          if (widget.errorWidgetBuilder != null) {
            return widget.errorWidgetBuilder(context, snapshot.error);
          }
        } else {
          if (widget.placeholderBuilder != null) {
            return widget.placeholderBuilder(context);
          }
        }
        return Container();
      },
    );
  }
}
