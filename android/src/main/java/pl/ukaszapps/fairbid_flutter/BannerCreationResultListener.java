package pl.ukaszapps.fairbid_flutter;

import android.util.Log;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.banner.BannerError;
import com.fyber.fairbid.ads.banner.BannerListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static pl.ukaszapps.fairbid_flutter.FairBidFlutterPlugin.runOnMain;

class BannerCreationResultListener implements BannerListener {

    private Map<String, MethodChannel.Result> resultCallbacks = new HashMap<>();
    @Override
    public void onError(@NonNull String s, final BannerError bannerError) {
    }

    @Override
    public void onLoad(@NonNull String s) {
        if (FairBidFlutterPlugin.debugLogging) {
            Log.d("BannerCreationL", "onLoad: " + s);
        }
        final MethodChannel.Result callback = resultCallbacks.remove(s);
        if (callback != null) {
            runOnMain(() -> callback.success(s));
        }
    }

    @Override
    public void onShow(@NonNull String s, @NonNull ImpressionData impressionData) {

    }

    @Override
    public void onClick(@NonNull String s) {

    }

    @Override
    public void onRequestStart(@NonNull String s) {

    }

    public void registerCallback(String placement, MethodChannel.Result result) {
        resultCallbacks.put(placement, result);
    }

    public void unregisterCallback(String placement) {
        resultCallbacks.remove(placement);
    }
}
