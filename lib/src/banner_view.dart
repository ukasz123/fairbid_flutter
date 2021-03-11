import 'dart:async';
import 'dart:io';

import 'package:fairbid_flutter/src/internal.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'package:fairbid_flutter/fairbid_flutter.dart';

// shared channel
const MethodChannel _methodChannel = FairBidInternal.methodCallChannel;

const EventChannel _metadataChannel = EventChannel("pl.ukaszapps.fairbid_flutter:bannerMetadata");

enum _BannerType { BANNER, RECTANGLE }

/// Builds widget in case error while requesting a banner fill.
typedef Widget ErrorWidgetBuilder(BuildContext context, Object error);

/// Presents native banner for the given placement.
/// **IMPORTANT**: You can present only one BannerView per placement on the screen at any given moment.
///
/// It depends on Platform Views. See documentation for [UiKitView](https://api.flutter.dev/flutter/widgets/UiKitView-class.html) and [AndroidView](https://api.flutter.dev/flutter/widgets/AndroidView-class.html) for limitations and necessary setup.
class BannerView extends StatelessWidget {
  final String placement;
  final FairBid sdk;
  final _BannerType type;
  final WidgetBuilder? placeholderBuilder;
  final ErrorWidgetBuilder? errorWidgetBuilder;

  const BannerView._(
      {Key? key,
      required this.placement,
      required this.sdk,
      this.placeholderBuilder,
      this.errorWidgetBuilder,
      required this.type})
      : super(key: key);

  /// Creates a widget that embeds a rectangle banner for a [placement].
  ///
  /// Tries to create a banner with aspect ratio closer to 1:1 than for regular banners.
  ///
  /// ⚠️ Rectangle size banners are NOT supported by FairBid SDK yet.
  // ignore: unused_element
  factory BannerView._rectangle(String placement, FairBid sdk,
          {WidgetBuilder? placeholderBuilder, ErrorWidgetBuilder? errorWidgetBuilder}) =>
      BannerView._(
        placement: placement,
        sdk: sdk,
        placeholderBuilder: placeholderBuilder,
        errorWidgetBuilder: errorWidgetBuilder,
        type: _BannerType.RECTANGLE,
      );

  /// Creates a widget that embeds a regular banner for a [placement].
  ///
  /// Tries to create a banner view for a [placement] using given [sdk].
  /// While loading it can show widget built with [placeholderBuilder].
  /// In case of error happening it presents the widget built with [errorWidgetBuilder].
  ///
  /// The widget would take all of the available width and enough height to present a native view.
  /// The expected height of the banner would be one of the following values: 50 for phones, 90 for tablets. Consider this values when using [placeholderBuilder] and [errorWidgetBuilder].
  /// The expected width of the banner is: 320 for phones and 728 for tablets although real values may vary.
  factory BannerView(String placement, FairBid sdk,
          {WidgetBuilder? placeholderBuilder, ErrorWidgetBuilder? errorWidgetBuilder}) =>
      BannerView._(
        placement: placement,
        sdk: sdk,
        placeholderBuilder: placeholderBuilder,
        errorWidgetBuilder: errorWidgetBuilder,
        type: _BannerType.BANNER,
      );

  @override
  Widget build(BuildContext context) {
    double height = 50.0;

    if (type == _BannerType.BANNER) {
      bool isTablet = MediaQuery.of(context).size.shortestSide > 600.0;
      height = isTablet ? 90 : 50;
    }
    // since FairBid 3.4.0 banner size depends on the device type
    return LayoutBuilder(builder: (context, constraints) {
      final viewConstraints = <String, int>{};
      viewConstraints["height"] =
          (constraints.hasBoundedHeight ? constraints.maxHeight : height).floor();

      // we need to tell native code what size of banners it can fit into the view

      // if (constraints.hasBoundedWidth) {
      //   viewConstraints["width"] = constraints.biggest.width.floor();
      // }

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

  final WidgetBuilder? placeholderBuilder;
  final ErrorWidgetBuilder? errorWidgetBuilder;

  const _FBNativeBanner(
      {Key? key,
      required this.placement,
      required this.sdk,
      required this.viewConstraints,
      this.placeholderBuilder,
      this.errorWidgetBuilder})
      : super(key: key);

  @override
  _FBNativeBannerState createState() => _FBNativeBannerState();
}

class _FBNativeBannerState extends State<_FBNativeBanner> {
  static final _messageCodec = const StandardMessageCodec();
  static final _viewType = "bannerView";

  late _FBBannerFactory _bannerFactory;

  late Future<dynamic> _loadFuture;

  late Stream<List<double>> _sizeStream;

  Map<String, dynamic> get bannerParams => Map<String, dynamic>.from(widget.viewConstraints)
    ..putIfAbsent("placement", () => widget.placement);

  @override
  void initState() {
    super.initState();

    _bannerFactory = _FBBannerFactory(widget.sdk);
    _loadFuture = _bannerFactory.load(bannerParams);
    _sizeStream = _bannerFactory.sizeStream(widget.placement);
  }

  @override
  void dispose() {
    _bannerFactory.dispose(widget.placement);

    super.dispose();
  }

  Widget? _nativeView;
  Widget get nativeView {
    Widget aView;
    if (_nativeView == null) {
      if (Platform.isAndroid) {
        aView = AndroidView(
          viewType: _viewType,
          creationParams: bannerParams,
          creationParamsCodec: _messageCodec,
        );
      } else {
        aView = UiKitView(
          viewType: _viewType,
          creationParams: bannerParams,
          creationParamsCodec: _messageCodec,
        );
      }
    } else {
      aView = _nativeView!;
    }
    return aView;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<double>>(
        stream: _loadFuture.asStream().asyncExpand((_) => _sizeStream),
        builder: (context, streamSnapshot) {
          if (streamSnapshot.hasData) {
            var data = streamSnapshot.data!;
            var size = Size(data[0], data[1]);
            if (size.isEmpty) {
              return widget.placeholderBuilder?.call(context) ?? SizedBox.shrink();
            } else {
              return Container(
                width: data[0],
                height: data[1],
                child: nativeView,
              );
            }
          } else if (streamSnapshot.hasError) {
            if (widget.errorWidgetBuilder != null) {
              return widget.errorWidgetBuilder?.call(context, streamSnapshot.error!) ?? SizedBox.shrink();
            }
          } else {
            if (widget.placeholderBuilder != null) {
              return widget.placeholderBuilder?.call(context) ?? SizedBox.shrink();
            }
          }
          return SizedBox.shrink();
        });
  }
}

class _FBBannerFactory {
  static _FBBannerFactory? _singleton;

  Timer? garbageCollector;

  final Map<String, Stream<List<double>>> _streamsCache = {};
  
  _FBBannerFactory._(this.sdk);

  factory _FBBannerFactory(FairBid sdk) {
    _singleton ??= _FBBannerFactory._(sdk);
    
    return _singleton!;
  }
  final FairBid sdk;
  final Map<String, _FBBannerFutureHolder> loadedBanners = {};

  Future<dynamic> load(Map<String, dynamic> bannerParams) {
    String placementId = bannerParams['placement'];

    _FBBannerFutureHolder? futureHolder = loadedBanners[placementId];
    if (futureHolder == null || futureHolder.error != null) {
      Future<dynamic> future = sdk.started.then((value) {
        if (value) {
          try {
            return _methodChannel
                .invokeMethod<dynamic>(
              "loadBanner",
              bannerParams,
            )
                .catchError((e, s) {
              if (e is PlatformException) {
                return Future.error('Banner not loaded (${e.code})', s);
              }
              return Future.error('Banner not loaded', s);
            });
          } catch (e, s) {
            if (e is PlatformException) {
              return Future.error('Banner not loaded (${e.code})', s);
            }
            return Future.error('Banner not loaded', s);
          }
        } else {
          return Future.error('SDK not started properly');
        }
      });
      loadedBanners[placementId] = _FBBannerFutureHolder(future, placementId)
        ..refCount = (futureHolder?.refCount ?? 0) + 1;
      return future;
    } else {
      futureHolder.refCount++;
      if (futureHolder.isFinished && futureHolder.isSuccess) {
        return Future.value(futureHolder.value);
      } else {
        return futureHolder.pending!;
      }
    }
  }

  void dispose(String placementId) {
    _FBBannerFutureHolder? futureHolder = loadedBanners[placementId];
    if (futureHolder != null) {
      futureHolder.refCount--;
      if (garbageCollector == null) {
        garbageCollector = Timer(const Duration(seconds: 8), () {
          garbageCollector = null;
          var toRemove =
              loadedBanners.values.where((holder) => holder.refCount <= 0).toList(growable: false);
          loadedBanners.removeWhere((key, holder) => holder.refCount <= 0);
          toRemove.forEach((element) {
            _methodChannel.invokeMethod<dynamic>(
              "destroyBanner",
              {"placement": element.placementId},
            ).catchError((e) {});
          });
        });
      }
    }
  }

  Stream<List<double>> sizeStream(String placementId) {
    Stream<List<double>>? s = _streamsCache[placementId];
    if (s == null) {
      s = _metadataChannel
          .receiveBroadcastStream(placementId)
          .map((data) => (data as List<dynamic>).cast<double>())
          // .distinct((l, r) =>
          //     l.length == r.length &&
          //     l.asMap().entries.fold(true,
          //         (previousValue, element) => element.value == r[element.key]))
          .where((data) => data[0] > 0.0 && data[1] > 0.0)
          .shareValue();
      _streamsCache[placementId] = s;
    }
    return s;
  }
}

class _FBBannerFutureHolder {
  Future<dynamic>? pending;
  dynamic? value;
  int refCount = 0;
  Future<dynamic>? error;

  String placementId;
  _FBBannerFutureHolder(Future<dynamic> pending, this.placementId) {
    this.pending = pending.then((value) {
      this.value = value;
      this.pending = null;
    }, onError: (error, stacktrace) {
      this.error = Future.error(error, stacktrace);
      this.pending = null;
      return this.error;
    });
  }

  bool get isFinished => pending == null;
  bool get isSuccess => value != null;

  @override
  String toString() {
    return "finished: $isFinished, success: $isSuccess, value: $value";
  }
}
