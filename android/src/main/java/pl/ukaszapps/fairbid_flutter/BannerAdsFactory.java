package pl.ukaszapps.fairbid_flutter;

import android.content.Context;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.banner.BannerAdView;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

import static pl.ukaszapps.fairbid_flutter.FairBidFlutterPlugin.debugLogging;

final class BannerAdsFactory extends PlatformViewFactory {

    private static final String TAG = "FlutterBannerFactory";
    private final DisplayMetrics metrics;
    private Map<String, BannerAdView> adsCache = new ConcurrentHashMap<>();
    private Map<String, EventChannel.EventSink> metadataSinks = new ConcurrentHashMap<>();

    BannerAdsFactory(BinaryMessenger messenger, Context context) {
        super(StandardMessageCodec.INSTANCE);
        this.metrics = context.getResources().getDisplayMetrics();
        EventChannel bannerMetadataChannel = new EventChannel(messenger, "pl.ukaszapps.fairbid_flutter:bannerMetadata");
        bannerMetadataChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                String placement = (String) o;
                Log.d(TAG, "onListen to metadata: " + placement);
                metadataSinks.put(placement, eventSink);
            }

            @Override
            public void onCancel(Object o) {
                Log.d(TAG, "onCancel to metadata: " + o);
                if (o != null) {
                    metadataSinks.remove(o);
                }
            }
        });
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        Map<String, Object> arguments = (Map<String, Object>) args;
        if (debugLogging) {
            Log.d(TAG, String.format("createPlatformView for %d with args: %s", viewId, arguments));
        }
        String placement = (String) arguments.get("placement");
        if (!TextUtils.isEmpty(placement) && TextUtils.isDigitsOnly(placement)) {
            BannerAdView cachedBanner = adsCache.get(placement);
            if (cachedBanner != null) {
                ViewParent parent = cachedBanner.getParent();
                if (parent != null) {
                    ((ViewGroup) parent).removeView(cachedBanner);
                }
                EventChannel.EventSink metadaChannel = metadataSinks.get(placement);
                if (metadaChannel != null) {
                    ArrayList<Double> size = getBannerMeasurements(cachedBanner);
                    metadaChannel.success(size);
                }
                return new BannerPlatformView(cachedBanner, Integer.parseInt(placement));
            }
        }
        TextView defaultView = new TextView(context);
        defaultView.setText("No banner available");
        return new DefaultPlatformView(defaultView);
    }

    void set(@NonNull final String placement, BannerAdView bannerView) {
        Utils.checkParameterIsNotNull(placement, "placementName");
        Log.d(TAG, "set view for " + placement + " => " + bannerView);
        if (bannerView == null) {
            adsCache.remove(placement);
        } else {
            adsCache.put(placement, bannerView);

            bannerView.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
                @Override
                public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
                    EventChannel.EventSink metadaChannel = metadataSinks.get(placement);
                    Log.d(TAG, "onLayoutChange: " + placement + " metadata = " + metadaChannel);
                    if (metadaChannel != null) {
                        ArrayList<Double> size = getBannerMeasurements((BannerAdView) v);

                        size.set(0, ((double) (right - left) / metrics.density));
                        size.set(1, ((double) (bottom - top) / metrics.density));

                        metadaChannel.success(size);
                    }
                }
            });
            EventChannel.EventSink metadaChannel = metadataSinks.get(placement);
            if (metadaChannel != null) {
                ArrayList<Double> size = getBannerMeasurements(bannerView);
                metadaChannel.success(size);
            }

        }
    }

    private class DefaultPlatformView implements PlatformView {

        private final View aView;

        private DefaultPlatformView(View aView) {
            this.aView = aView;
        }


        @Override
        public View getView() {
            return aView;
        }

        @Override
        public void dispose() {

        }
    }

    private class BannerPlatformView implements PlatformView {

        private final BannerAdView bannerView;
        private final int placement;

        private BannerPlatformView(BannerAdView bannerView, int placement) {
            this.bannerView = bannerView;
            this.placement = placement;
        }

        @Override
        public View getView() {
            bannerView.load(placement);
            return bannerView;
        }

        @Override
        public void dispose() {
            bannerView.destroy();
        }
    }

    static ArrayList<Double> getBannerMeasurements(BannerAdView bannerAdView) {
        DisplayMetrics metrics = bannerAdView.getResources().getDisplayMetrics();
        View bannerChild = bannerAdView.getChildAt(0);
        ArrayList<Double> size;
        if (bannerChild != null) {
            size = new ArrayList<>(Arrays.asList(
                    ((double) bannerChild.getLayoutParams().width / metrics.density),
                    ((double) bannerChild.getLayoutParams().height / metrics.density),
                    ((double) bannerAdView.getWidth() / metrics.density),
                    ((double) bannerAdView.getHeight() / metrics.density),
                    ((double) bannerAdView.getMeasuredWidth() / metrics.density),
                    ((double) bannerAdView.getMeasuredHeight() / metrics.density)));
        } else {
            size = new ArrayList<>(Arrays.asList(
                    ((double) bannerAdView.getWidth() / metrics.density),
                    ((double) bannerAdView.getHeight() / metrics.density),
                    ((double) bannerAdView.getMeasuredWidth() / metrics.density),
                    ((double) bannerAdView.getMeasuredHeight() / metrics.density)));
        }
        return size;
    }
}
