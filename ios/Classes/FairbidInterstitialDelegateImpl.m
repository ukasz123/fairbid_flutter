#import <Foundation/Foundation.h>
#import "FairbidFlutterPlugin.h"

@interface EventProducingInterstitialDelegateImpl ()

@property (nonatomic, copy) EventSender sender;
@end

@implementation EventProducingInterstitialDelegateImpl

static NSString *const _AD_TYPE = @"interstitial";

//// EventProducer

- (void)setEventSender:(EventSender)sender {
    self.sender = sender;
}

- (void)sendEvent:(NSString *)event forPlacement:(NSString *)placementId withImpressionData:(FYBImpressionData *)impressionData {
    if (self.sender) {
        self.sender(_AD_TYPE, placementId, event, impressionData, nil);
    } else {
        NSLog(@"no sender set!!");
    }
}

- (void)sendEvent:(NSString *)event forPlacement:(NSString *)placementId {
    [self sendEvent:event forPlacement:placementId withImpressionData:nil];
}

//// FYBInterstitialDelegate
- (void)interstitialIsAvailable:(NSString *)placementId {
    [self sendEvent:@"available" forPlacement:placementId];
}

- (void)interstitialIsUnavailable:(NSString *)placementId {
    //    Called when an Interstitial from placement becomes unavailable
    [self sendEvent:@"unavailable" forPlacement:placementId];
}

- (void)interstitialDidShow:(nonnull NSString *)placementId impressionData:(nonnull FYBImpressionData *)impressionData {
    //    Called when an Interstitial from placement shows up
    [self sendEvent:@"show" forPlacement:placementId withImpressionData:impressionData];
}

- (void)interstitialDidFailToShow:(nonnull NSString *)placementId withError:(NSError *)error impressionData:(nonnull FYBImpressionData *)impressionData {
    //    Called when an error arises when showing an Interstitial from placement
    [self sendEvent:@"showFailure" forPlacement:placementId withImpressionData:impressionData];
}

- (void)interstitialDidClick:(NSString *)placementId {
    //    Called when an Interstitial from placement is clicked
    [self sendEvent:@"click" forPlacement:placementId];
}

- (void)interstitialDidDismiss:(NSString *)placementId {
    //    Called when an Interstitial from placement hides
    [self sendEvent:@"hide" forPlacement:placementId];
}

- (void)interstitialWillStartAudio {
    //    Called when an Interstitial will start audio
}

- (void)interstitialDidFinishAudio {
    //    Called when an Interstitial finishes playing audio
}

- (void)interstitialWillRequest:(NSString *)placementId {
    [self sendEvent:@"request" forPlacement: placementId];
}

@end

