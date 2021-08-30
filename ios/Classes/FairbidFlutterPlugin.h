#import <Flutter/Flutter.h>
#import <FairBidSDK/FairBidSDK.h>

@interface AdapterStartedStreamHandler :NSObject<FlutterStreamHandler>

- (void)sendAdapterStartEvent:(NSString *_Nonnull)name version:(NSString *_Nonnull)version message: ( NSString* _Nullable) message;

@end

@interface FairbidFlutterPlugin : NSObject<FlutterPlugin, FlutterStreamHandler, FairBidDelegate>

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

- (void)registerResultCallback:(FlutterResult _Nonnull )result forPlacement:(NSString *_Nonnull) placementId;

- (void)loadBanner:(NSString *)placement width:(NSNumber *)width height:(NSNumber *)height andResult:(FlutterResult)result;

- (void)destroyBanner:(NSString *)placementId;

- (id)initWith:(NSObject<FlutterBinaryMessenger> *_Nonnull)messenger;
@end
