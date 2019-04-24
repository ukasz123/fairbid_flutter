package pl.ukaszapps.fairbid_flutter;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.banner.BannerError;
import com.fyber.fairbid.ads.banner.BannerListener;
import com.fyber.fairbid.internal.Constants;

public final class BannerEventProducer implements BannerListener {
    private final EventSender sendEvent;

    public BannerEventProducer(@NonNull EventSender sendEvent) {
        this.sendEvent = sendEvent;
    }

    @Override
    public void onError(@NonNull String placement, BannerError bannerError) {
        Utils.checkParameterIsNotNull(placement, "placement");
        String errorMessage = bannerError.getErrorMessage();
        this.sendEvent.send(Constants.AdType.BANNER, placement, "error" , null,  (errorMessage != null) ? bannerError.getErrorMessage() : "no message");
    }

    @Override
    public void onLoad(@NonNull String placement) {

        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.BANNER, placement, "load", null);
    }

    @Override
    public void onShow(@NonNull String placement, @NonNull ImpressionData impressionData) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.BANNER, placement, "show", impressionData);
    }

    @Override
    public void onClick(@NonNull String placement) {

        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.BANNER, placement, "click", null);
    }

    @Override
    public void onRequestStart(@NonNull String placement) {
        Utils.checkParameterIsNotNull(placement, "placement");
        this.sendEvent.send(Constants.AdType.BANNER, placement, "request", null);
    }
}
