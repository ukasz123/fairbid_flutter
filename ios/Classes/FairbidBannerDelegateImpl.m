//
//  FairbidBannerDelegateImpl.m
//  fairbid_flutter
//
#import <Foundation/Foundation.h>
#import "FairbidFlutterPlugin.h"
#import <Flutter/Flutter.h>



@interface BannerPlatformView: NSObject<FlutterPlatformView>
@property (nonatomic) FYBBannerAdView *bannerView;
@property (nonatomic) UIView *frameView;
- (id)initWithBanner: (FYBBannerAdView *)banner and: (CGRect)frame;

@end

@implementation BannerPlatformView

- (id)initWithBanner: (FYBBannerAdView *)banner and: (CGRect)frame {
    if ([super init]) {
        _bannerView = banner;
        _frameView = [[UIView alloc] initWithFrame: frame];
        [_frameView addSubview: banner];
    }
    return self;
}

- (UIView*)view {
    return _frameView;
}

@end

@interface BannerDelegateImpl ()

@property (nonatomic, copy) EventSender sender;

@end


@implementation BannerDelegateImpl

static NSString *const _AD_TYPE = @"banner";

- (void)bannerDidLoad:(FYBBannerAdView *)banner {
    FlutterResult result = [callbacks valueForKey:banner.options.placementId];
    if (result){
        NSLog(@"[FB_Flutter] banner loaded %@",banner.options.placementId);
        CGSize size = banner.frame.size;
        
        NSArray *sizeArray = @[[NSNumber numberWithDouble:size.width], [NSNumber numberWithDouble:size.height]];
        NSLog(@"[FB_Flutter] banner loaded %@ [%@]",banner.options.placementId, sizeArray);
        FlutterEventSink metadataSink = [metadataSinks objectForKey:banner.options.placementId];
        if (metadataSink){
            metadataSink(sizeArray);
        }
        result( sizeArray );
        [callbacks setValue:nil forKey:banner.options.placementId];
    }
    
    [ads setObject:banner forKey:banner.options.placementId];
    [self sendEvent:@"load" forPlacement: banner.options.placementId];
}

- (void)bannerDidFailToLoad:(NSString *)placementId withError:(NSError *)error {
    [self sendEvent:@"error" forPlacement:placementId];
}

- (void)bannerDidShow:(FYBBannerAdView *)banner impressionData:(nonnull FYBImpressionData *)impressionData {
    [self sendEvent:@"show" forPlacement: banner.options.placementId withImpressionData:impressionData];
}

- (void)bannerDidClick:(FYBBannerAdView *)banner {
    [self sendEvent:@"click" forPlacement: banner.options.placementId];
}

- (void)bannerWillPresentModalView:(FYBBannerAdView *)banner {
    //    Called when banner presents modal view
}

- (void)bannerDidDismissModalView:(FYBBannerAdView *)banner {
    //    Called when banner hides presented modal view
}

- (void)bannerWillLeaveApplication:(FYBBannerAdView *)banner {
    //    Called after banner redirects to other application
}

- (void)banner:(FYBBannerAdView *)banner didResizeToFrame:(CGRect)frame {
    if (self.sender) {
        self.sender(_AD_TYPE, banner.options.placementId, @"bannerResize",nil,
  @[[NSNumber numberWithDouble: frame.size.width], [NSNumber numberWithDouble: frame.size.height]]
                    );
    }
    FlutterEventSink metadataSink = [metadataSinks objectForKey:banner.options.placementId];
    if (metadataSink){
        NSArray *size = @[[NSNumber numberWithDouble:frame.size.width], [NSNumber numberWithDouble:frame.size.height]];
        metadataSink(size);
    }
}

- (void)bannerWillRequest:(NSString *)placementId {
    [self sendEvent:@"request" forPlacement: placementId];
}

//// EventProducer

- (void)setEventSender:(EventSender)sender {
    self.sender = sender;
}

- (void)sendEvent:(NSString *)event forPlacement:(NSString *)placement {
    [self sendEvent:event forPlacement:placement withImpressionData:nil];
}

- (void)sendEvent:(NSString *)event forPlacement:(NSString *)placement withImpressionData: (FYBImpressionData *)impressionData{
    if (self.sender) {
        self.sender(_AD_TYPE, placement, event, impressionData, nil);
    } else {
           NSLog(@"no sender set!!");
    }
}

//// Native view banners
- (void)loadBanner:(NSString *)placement width:(NSNumber *)width height:(NSNumber *)height andResult:(FlutterResult)result {
    
    FYBBannerAdView *bannerView = [ads objectForKey:placement];
    if (bannerView){
        NSLog(@"[FB_Flutter] banner loaded %@",bannerView.options.placementId);
        CGSize size = bannerView.frame.size;
        
        NSArray *sizeArray = @[[NSNumber numberWithDouble:size.width], [NSNumber numberWithDouble:size.height]];
        NSLog(@"[FB_Flutter] banner loaded %@ [%@]",bannerView.options.placementId, sizeArray);
        FlutterEventSink metadataSink = [metadataSinks objectForKey:bannerView.options.placementId];
        if (metadataSink){
            metadataSink(sizeArray);
        }
        result( sizeArray );
        // return early
        return;
    }
    
    FYBBannerOptions *bannerOptions = [[FYBBannerOptions alloc] init];
    bannerOptions.placementId = placement;
    NSLog(@"[FB_Flutter] Load banner %@ (%@, %@)", placement, width, height);
    [self registerResultCallback:result forPlacement:placement];
    [FYBBanner requestWithOptions:bannerOptions];
}

- (void)destroyBanner:(NSString *)placement {
    FYBBannerAdView *bannerView = [ads objectForKey:placement];
    if (bannerView){
        [bannerView removeFromSuperview];
        [ads removeObjectForKey:placement];
        [metadataSinks removeObjectForKey:placement];
    }
    [FYBBanner destroy: placement];
    
    NSLog(@"[FB_Flutter] destroyBanner %@ - done", placement);
}


//// FlutterPlatformViewFactory

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    
    NSDictionary *arguments = args;
    NSString *placement = arguments[@"placement"];
    // NSNumber *width = arguments[@"width"];
    // NSNumber *height = arguments[@"height"];
    NSLog(@"[FB_Flutter] createWithFrame %@ for frame [%f x %f]", placement, frame.size.width, frame.size.height);
    
    FYBBannerAdView *bannerView = [ads objectForKey:placement];
    
    NSLog(@"[FB_Flutter] createWithFrame found banner %lu with frame [%f x %f]", [bannerView hash], bannerView.frame.size.width, bannerView.frame.size.height);
    FlutterEventSink metadataSink = [metadataSinks objectForKey:placement];
    if (metadataSink){
        NSArray *size = @[[NSNumber numberWithDouble:bannerView.frame.size.width], [NSNumber numberWithDouble:bannerView.frame.size.height]];
        metadataSink(size);
    }
    return [[BannerPlatformView alloc] initWithBanner:bannerView and: frame];
    
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

//// FlutterStreamHandler protocol
NSMutableDictionary *metadataSinks;
- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    if (arguments) {
        NSString* placement = arguments;
        [metadataSinks removeObjectForKey:placement];
    }
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (arguments) {
        NSString* placement = arguments;
        NSLog(@"[FB_Flutter] onListenWithArguments %@", placement);
        [metadataSinks setObject:events forKey:placement];
        FYBBannerAdView *bannerView = [ads objectForKey:placement];
        if (bannerView){
            NSArray *size = @[[NSNumber numberWithDouble:bannerView.frame.size.width], [NSNumber numberWithDouble:bannerView.frame.size.height]];
            events(size);
        }
    }
    return nil;
}

//// other
NSMutableDictionary *callbacks;
NSMutableDictionary *ads;

- (id)initWith: (NSObject<FlutterBinaryMessenger> *) messenger {
    callbacks = [NSMutableDictionary dictionary];
    ads = [NSMutableDictionary dictionary];
    metadataSinks = [NSMutableDictionary dictionary];
    
    FlutterEventChannel *metadataEventsChannel = [FlutterEventChannel eventChannelWithName:@"pl.ukaszapps.fairbid_flutter:bannerMetadata" binaryMessenger:messenger];
    [metadataEventsChannel setStreamHandler: self];
    return self;
}

- (void)registerResultCallback:(FlutterResult)result forPlacement:(NSString *)placement {
    
    NSLog(@"[FB_Flutter] registerResultCallback %@", placement);
    [callbacks setValue:result forKey:placement];
}

@end
