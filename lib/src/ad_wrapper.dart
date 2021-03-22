

part of 'internal.dart';

abstract class _AdWrapper with _EventsProvider {
  _AdWrapper._(this._sdk, this._type, this.placementId)
      : 
        assert(
            placementId.isNotEmpty &&
            _isCorrectId(placementId));

  final String placementId;

  /// Returns [Future] that resolves to `true` if an ad is available for showing. If ad is not available yet then it would resolve to `false`.
  Future<bool> get isAvailable => _sdk._available(_type, placementId);

  /// Returns stream of availability changes. Listening to this stream is preferred
  /// if you need to know whether ad is available as soon as possible.
  Stream<bool> get availabilityStream => _startWithFuture(
          isAvailable, simpleEvents)
      .where((event) =>
          event == AdEventType.available || event == AdEventType.unavailable)
      .map((event) => event == AdEventType.available)
      .asBroadcastStream();

  /// Requests for the fill for [placementId]. It has to be called before [show].
  /// Consider calling this method as soon as possible to get the fill for showing when ad should be shown in your app flow.
  Future<void> request() => _sdk._request(_type, placementId);

  /// Shows the ad for [placementId]. The ad has to be available to make this work. See [isAvailable].
  Future<void> show() => _sdk._show(_type, placementId);

  /// Shows the ad for [placementId] with server side rewarding parameters for the impression. See [server side rewarding documentation](https://developer.fyber.com/hc/en-us/articles/360009923657-Server-Side-Rewarding)
  /// The ad has to be available to make this work. See [isAvailable].
  Future<void> showWithSSR({required Map<String, String> serverSideRewardingOptions}) =>
      _sdk._show(_type, placementId,
          extraOptions: serverSideRewardingOptions);

  /// Changes auto-requesting behavior for this [placementId].
  ///
  /// Returnes [Future] that resolves to [autoRequestingEnabled] value when operation succeeds.
  Future<bool> changeAutoRequesting(bool autoRequestingEnabled) =>
      _sdk._changeAutoRequesting(_type, placementId, autoRequestingEnabled) as Future<bool>;

  final FairBidInternal _sdk;

  final AdType _type;
}

// utility method - returns the stream with a first element being result of future passed and the rest elements coming from the tail stream
Stream<T> _startWithFuture<T>(Future<T> first, Stream<T> tail) async* {
  yield await first;
  await for (var t in tail) {
    yield t;
  }
}

// checking if placementId is a correct number
var _idRegExp = RegExp(r'^[1-9][0-9]*$');
bool _isCorrectId(String id) => _idRegExp.hasMatch(id);
