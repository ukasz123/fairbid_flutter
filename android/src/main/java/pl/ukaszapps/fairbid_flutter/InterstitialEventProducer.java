package pl.ukaszapps.fairbid_flutter;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.interstitial.InterstitialListener;
import com.fyber.fairbid.internal.Constants;


final class InterstitialEventProducer implements InterstitialListener {
    @NonNull
    private final EventSender sendEvent;

    @Override
    public void onShow(@NonNull String placement, @NonNull ImpressionData impressionData) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "show", impressionData);
    }

    public void onClick(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "click", null);
    }


    public void onUnavailable(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "unavailable", null);
    }

    @Override
    public void onRequestStart(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "request", null);
    }

    public void onAvailable(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "available", null);
    }

    public void onHide(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "hide", null);
    }

    @Override
    public void onShowFailure(@NonNull String placement, @NonNull ImpressionData impressionData) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.INTERSTITIAL, placement, "showFailure", impressionData);
    }


    InterstitialEventProducer(@NonNull EventSender sendEvent) {
        Utils.checkParameterIsNotNull(sendEvent, "sendEvent");
        this.sendEvent = sendEvent;
    }
}
