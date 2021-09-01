//
//  FairbidRewardedDelegate.m
//  fairbid_flutter
//

#import <Foundation/Foundation.h>
#import "FairbidFlutterPlugin.h"

@interface EventProducingRewardedDelegateImpl ()

@property (nonatomic, copy) EventSender sender;
@end

@implementation EventProducingRewardedDelegateImpl

static NSString *const _AD_TYPE = @"rewarded";

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

/// FYBRewardedDelegate

- (void)rewardedIsAvailable:(NSString *)placementId {
    //    Called when a rewarded ad from placement becomes available
    [self sendEvent: @"available" forPlacement: placementId];
}

- (void)rewardedIsUnavailable:(NSString *)placementId {
    //    Called when a rewarded ad from placement becomes unavailable
    [self sendEvent: @"unavailable" forPlacement: placementId];
}

- (void)rewardedDidShow:(nonnull NSString *)placementId impressionData:(nonnull FYBImpressionData *)impressionData {
    //    Called when a rewarded ad from placement shows up
    [self sendEvent: @"show" forPlacement: placementId withImpressionData:impressionData];
}

- (void)rewardedDidFailToShow:(nonnull NSString *)placementId withError:(NSError *)error impressionData:(nonnull FYBImpressionData *)impressionData {
    //    Called when an error arises when showing a rewarded ad from placement
    [self sendEvent: @"showFailure" forPlacement: placementId withImpressionData:impressionData];
}

- (void)rewardedDidClick:(NSString *)placementId {
    //    Called when a rewarded ad from placement is clicked
    [self sendEvent: @"click" forPlacement: placementId];
}

- (void)rewardedDidDismiss:(NSString *)placementId {
    //    Called when a rewarded ad from placement hides
    [self sendEvent: @"hide" forPlacement: placementId];
}

- (void)rewardedDidComplete:(NSString *)placementId userRewarded:(BOOL)userRewarded {
    //    Called when a rewarded ad finishes playing
    if (self.sender) {
        self.sender(_AD_TYPE, placementId, @"completion", nil, @[[NSNumber numberWithBool:userRewarded]]);
    } else {
        NSLog(@"no sender set!!");
    }
}

- (void)rewardedWillStartAudio {
    //    Called when a rewarded ad will start audio
}

- (void)rewardedDidFinishAudio {
    // Called when a rewarded ad finishes playing audio
}

- (void)rewardedWillRequest:(NSString *)placementId {
    [self sendEvent:@"request" forPlacement: placementId];
}
@end

