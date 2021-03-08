package pl.ukaszapps.fairbid_flutter;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.rewarded.RewardedListener;
import com.fyber.fairbid.internal.Constants;


final class RewardedEventProducer implements RewardedListener {
    private final EventSender sendEvent;

    @Override
    public void onShow(@NonNull String placement, @NonNull ImpressionData impressionData) {

        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "show", impressionData);
    }

    public void onClick(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "click", null);
    }

    public void onUnavailable(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "unavailable", null);
    }

    public void onCompletion(@NonNull String placement, boolean userRewarded) {
        Utils.checkParameterIsNotNull(placement, "placement");
        if (userRewarded) {
            this.sendEvent.send(Constants.AdType.REWARDED, placement, "completion", null, userRewarded);
        } else {
            this.sendEvent.send(Constants.AdType.REWARDED, placement, "notCompletion", null, userRewarded);
        }
    }

    @Override
    public void onRequestStart(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "request", null);
    }

    public void onAvailable(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "available", null);
    }

    public void onHide(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "hide", null);
    }

    @Override
    public void onShowFailure(@NonNull String placement, @NonNull ImpressionData impressionData) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.REWARDED, placement, "showFailure", impressionData);

    }

    public RewardedEventProducer(@NonNull EventSender sendEvent) {
        Utils.checkParameterIsNotNull(sendEvent, "sendEvent");
        this.sendEvent = sendEvent;
    }
}

