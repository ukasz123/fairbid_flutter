#import <Flutter/Flutter.h>
#import <FairBidSDK/FairBidSDK.h>

@interface FairBidFlutterPlugin : NSObject<FlutterPlugin, FlutterStreamHandler>

@end

typedef void (^ EventSender)(NSString *type, NSString *placementId, NSString *eventName, FYBImpressionData *impressionData, NSArray *extras);

@protocol EventProducer<NSObject>

- (void)setEventSender:(EventSender)sender;

@end

@interface EventProducingInterstitialDelegateImpl : NSObject<FYBInterstitialDelegate, EventProducer>

@end

@interface EventProducingRewardedDelegateImpl : NSObject<FYBRewardedDelegate, EventProducer>

@end

@interface BannerDelegateImpl: NSObject<FYBBannerDelegate, EventProducer, FlutterPlatformViewFactory, FlutterStreamHandler>

- (void)registerResultCallback:(FlutterResult)result forPlacement:(NSString *) placementId;

- (void)destroyBanner:(NSString *)placementId;

- (id)initWith:(NSObject<FlutterBinaryMessenger> *)messenger;
@end
