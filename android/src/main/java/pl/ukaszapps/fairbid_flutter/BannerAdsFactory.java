package pl.ukaszapps.fairbid_flutter;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.Banner;
import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.banner.BannerError;
import com.fyber.fairbid.ads.banner.BannerListener;
import com.fyber.fairbid.ads.banner.BannerOptions;

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

final class BannerAdsFactory extends PlatformViewFactory implements BannerListener {

    private static final String TAG = "FlutterBannerFactory";
    private static final int BANNER_MIN_WIDTH_PHONE = 320;
    private static final int BANNER_MIN_WIDTH_TABLET = 728;
    private static final int BANNER_MIN_HEIGHT_PHONE = 50;
    private static final int BANNER_MIN_HEIGHT_TABLET = 90;
    private final Map<String, ViewGroup> adsCache = new ConcurrentHashMap<>();
    private final Map<String, EventChannel.EventSink> metadataSinks = new ConcurrentHashMap<>();

    BannerAdsFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        EventChannel bannerMetadataChannel = new EventChannel(messenger,
                                                              "pl.ukaszapps.fairbid_flutter:bannerMetadata"
        );
        bannerMetadataChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                String placement = (String) o;

                EventChannel.EventSink previous = metadataSinks.put(placement, eventSink);
                if (previous != null) {
                    previous.endOfStream();
                }
                ViewGroup adView = adsCache.get(placement);
                if (adView != null) {
                    eventSink.success(getBannerMeasurements(adView));
                }
            }

            @Override
            public void onCancel(Object o) {
                if (o != null) {
                    metadataSinks.remove(o);
                }
            }
        });
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        @SuppressWarnings("unchecked") Map<String, Object> arguments = (Map<String, Object>) args;
        if (debugLogging) {
            Log.d(TAG, String.format("createPlatformView for %d with args: %s", viewId, arguments));
        }
        String placement = (String) arguments.get("placement");
        if (!TextUtils.isEmpty(placement) && TextUtils.isDigitsOnly(placement)) {
            final ViewGroup cachedBanner = adsCache.get(placement);
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
                return new BannerPlatformView(cachedBanner);
            }
        }
        TextView defaultView = new TextView(context);
        defaultView.setText("No banner available");
        return new DefaultPlatformView(defaultView);
    }

    ViewGroup get(@NonNull final String placement) {
        Utils.checkParameterIsNotNull(placement, "placementName");
        return adsCache.get(placement);
    }

    void set(@NonNull final String placement, ViewGroup bannerView) {
        Utils.checkParameterIsNotNull(placement, "placementName");
        if (bannerView == null) {
            ViewGroup toRemove = adsCache.remove(placement);
            if (toRemove != null) {
                if (debugLogging) {
                    Log.d(TAG, "removing banner: " + toRemove);
                }
                Banner.destroy(placement);
            }
        } else {
            ViewGroup toRemove = adsCache.put(placement, bannerView);
            if (toRemove != null) {
                if (debugLogging) {
                    Log.w(TAG, "replacing previous banner: " + toRemove);
                }
            }

            View actualBanner = bannerView.getChildAt(0);
            if (actualBanner != null) {
                actualBanner.addOnLayoutChangeListener((v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) -> {
                    EventChannel.EventSink metadaChannel = metadataSinks.get(placement);
                    if (metadaChannel != null) {
                        float density = v.getResources().getDisplayMetrics().density;
                        ArrayList<Double> size = new ArrayList<>(Arrays.asList((double) ((right - left) / density),
                                                                               (double) ((bottom - top) / density)
                        ));
                        metadaChannel.success(size);
                    }
                });
            }
            EventChannel.EventSink metadaChannel = metadataSinks.get(placement);
            if (metadaChannel != null) {
                ArrayList<Double> size = getBannerMeasurements(bannerView);
                metadaChannel.success(size);
            }

        }
    }

    boolean hasBanner(String placement) {
        return adsCache.containsKey(placement);
    }

    void createBannerView(Activity activity, String placement, Integer requestedWidth, Integer requestedHeight) {
        int placementId = Integer.parseInt(placement);
        DisplayMetrics metrics = activity.getResources().getDisplayMetrics();

        final BannerOptions bannerOptions = new BannerOptions();
        int tempWidth = BANNER_MIN_WIDTH_PHONE;
        if (Utils.isTablet(activity)) {
            tempWidth = BANNER_MIN_WIDTH_TABLET;
        }
        if (requestedWidth != null) {
            tempWidth = ((Number) (requestedWidth)).intValue();
        }

        int tempHeight = BANNER_MIN_HEIGHT_PHONE;
        if (Utils.isTablet(activity)) {
            tempHeight = BANNER_MIN_HEIGHT_TABLET;
        }
        if (requestedHeight != null) {
            tempHeight = ((Number) (requestedHeight)).intValue();
        }

        FrameLayout bannerFrame = new FrameLayout(activity);
        FrameLayout.LayoutParams bannerFrameLayoutParams = new FrameLayout.LayoutParams(
                (int) (tempWidth * metrics.density),
                (int) (tempHeight * metrics.density)
        );
        bannerFrame.setLayoutParams(bannerFrameLayoutParams);

        bannerOptions.placeInContainer(bannerFrame);

        if (debugLogging) {
            Log.d(TAG,
                  String.format("placing banner in the frame (%d, %d)", tempWidth, tempHeight)
            );
        }
        Banner.show(placement, bannerOptions, activity);
        this.set(placement, bannerFrame);
    }

    @Override
    public void onError(@NonNull String placementId, BannerError bannerError) {
        
    }

    @Override
    public void onLoad(@NonNull String s) {

    }

    @Override
    public void onShow(@NonNull String placementId, @NonNull ImpressionData impressionData) {
        ViewGroup adView = adsCache.get(placementId);
        EventChannel.EventSink sizeSink = metadataSinks.get(placementId);
        if (adView != null && sizeSink != null) {
            ArrayList<Double> size = getBannerMeasurements(adView);
            sizeSink.success(size);
        }
    }

    @Override
    public void onClick(@NonNull String s) {

    }

    @Override
    public void onRequestStart(@NonNull String s) {

    }

    private static class DefaultPlatformView implements PlatformView {

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

    private static class BannerPlatformView implements PlatformView {

        private final View bannerView;

        private BannerPlatformView(View bannerView) {
            this.bannerView = bannerView;
        }

        @Override
        public View getView() {
            if (debugLogging) {
                Log.d(TAG, "getView Banner");
            }
            return bannerView;
        }

        @Override
        public void dispose() {
            // do nothing
        }
    }

    static ArrayList<Double> getBannerMeasurements(ViewGroup bannerAdView) {
        DisplayMetrics metrics = bannerAdView.getResources().getDisplayMetrics();
        View bannerChild = bannerAdView.getChildAt(0);

        ArrayList<Double> size;
        double childWidth = 0;
        double childHeight = 0;

        ViewGroup.LayoutParams bannerAdViewLP = bannerAdView.getLayoutParams();
        if (bannerChild != null) {
            ViewGroup.LayoutParams temp = bannerChild.getLayoutParams();
            if (temp != null) {
                childWidth = temp.width;
                childWidth = childWidth < 0 ? (bannerAdViewLP != null ? bannerAdViewLP.width : -1) : childWidth;
                childHeight = temp.height;
                childHeight = childHeight < 0 ? (bannerAdViewLP != null ? bannerAdViewLP.height : -1) : childHeight;
            }

        }
        size = new ArrayList<>(Arrays.asList(
                (childWidth / metrics.density),
                (childHeight / metrics.density),
                ((double) bannerAdView.getWidth() / metrics.density),
                ((double) bannerAdView.getHeight() / metrics.density),
                ((double) bannerAdView.getMeasuredWidth() / metrics.density),
                ((double) bannerAdView.getMeasuredHeight() / metrics.density)
        ));
        return size;
    }
}
