package pl.ukaszapps.fairbid_flutter;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.banner.BannerError;
import com.fyber.fairbid.ads.banner.BannerListener;

class CombinedBannerListener implements BannerListener {
    private final BannerListener[] listeners;

    CombinedBannerListener(BannerListener[] listeners) {
        this.listeners = listeners;
    }

    @Override
    public void onError(@NonNull String placement, BannerError bannerError) {
        for (BannerListener listener : listeners) {
            listener.onError(placement, bannerError);
        }
    }

    @Override
    public void onLoad(@NonNull String placement) {
        for (BannerListener listener : listeners) {
            listener.onLoad(placement);
        }
    }

    @Override
    public void onShow(@NonNull String placement, @NonNull ImpressionData impressionData) {
        for (BannerListener listener : listeners) {
            listener.onShow(placement, impressionData);
        }
    }

    @Override
    public void onClick(@NonNull String placement) {
        for (BannerListener listener : listeners) {
            listener.onClick(placement);
        }
    }

    @Override
    public void onRequestStart(@NonNull String placement) {
        for (BannerListener listener : listeners) {
            listener.onRequestStart(placement);
        }
    }
}
