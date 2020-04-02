package pl.ukaszapps.fairbid_flutter;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.fyber.fairbid.ads.CreativeSize;
import com.fyber.fairbid.ads.banner.BannerAdView;
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

import static com.fyber.fairbid.ads.CreativeSize.SMART_BANNER;
import static pl.ukaszapps.fairbid_flutter.FairBidFlutterPlugin.debugLogging;

final class BannerAdsFactory extends PlatformViewFactory {

    private static final String TAG = "FlutterBannerFactory";
    private Map<String, BannerAdView> adsCache = new ConcurrentHashMap<>();
    private Map<String, EventChannel.EventSink> metadataSinks = new ConcurrentHashMap<>();

    BannerAdsFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        EventChannel bannerMetadataChannel = new EventChannel(messenger,
                                                              "pl.ukaszapps.fairbid_flutter:bannerMetadata"
        );
        bannerMetadataChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                String placement = (String) o;
                metadataSinks.put(placement, eventSink);
                BannerAdView adView = adsCache.get(placement);
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
            final BannerAdView cachedBanner = adsCache.get(placement);
            if (cachedBanner != null) {

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

    BannerAdView get(@NonNull final String placement) {
        Utils.checkParameterIsNotNull(placement, "placementName");
        return adsCache.get(placement);
    }

    void set(@NonNull final String placement, BannerAdView bannerView) {
        Utils.checkParameterIsNotNull(placement, "placementName");
        if (bannerView == null) {
            BannerAdView toRemove = adsCache.remove(placement);
            if (toRemove != null) {
                if (debugLogging) {
                    Log.d(TAG, "removing banner: " + toRemove);
                }
                toRemove.destroy();
            }
        } else {
            BannerAdView toRemove = adsCache.put(placement, bannerView);

            if (toRemove != null) {
                if (debugLogging) {
                    Log.d(TAG, "replacing banner: " + toRemove);
                }
                toRemove.destroy();
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

        final BannerAdView bannerView = new BannerAdView(activity, placementId);

        final BannerOptions bannerOptions = new BannerOptions();
        CreativeSize.Builder sizeBuilder = CreativeSize.Builder.newBuilder();
        int tempWidth = ViewGroup.LayoutParams.MATCH_PARENT;
        if (requestedWidth != null) {
            tempWidth = ((Number) (requestedWidth)).intValue();
            sizeBuilder.withWidth(tempWidth);
        }
        int tempHeight = ViewGroup.LayoutParams.WRAP_CONTENT;
        if (requestedHeight != null) {
            tempHeight = ((Number) (requestedHeight)).intValue();
            sizeBuilder.withHeight(tempHeight);
        }

        bannerView.setBannerOptions(bannerOptions.setFallbackSize(SMART_BANNER));
        FrameLayout bannerFrame = new FrameLayout(activity);
        FrameLayout.LayoutParams bannerFrameLayoutParams = new FrameLayout.LayoutParams(
                (int) (tempWidth * metrics.density),
                (int) (tempHeight * metrics.density)
        );
        bannerView.setLayoutParams(bannerFrameLayoutParams);

        bannerOptions.placeInContainer(bannerFrame);
        if (debugLogging) {
            Log.d(TAG,
                  String.format("placing banner in the frame (%d, %d)", tempWidth, tempHeight)
            );
        }
        bannerView.load(placementId, true);
        this.set(placement, bannerView);
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

        private final BannerAdView bannerView;

        private BannerPlatformView(BannerAdView bannerView) {
            this.bannerView = bannerView;
        }

        @Override
        public View getView() {
            return bannerView;
        }

        @Override
        public void dispose() {
            // do nothing
        }
    }

    static ArrayList<Double> getBannerMeasurements(BannerAdView bannerAdView) {
        DisplayMetrics metrics = bannerAdView.getResources().getDisplayMetrics();
        View bannerChild = bannerAdView.getChildAt(0);
        ArrayList<Double> size;
        double childWidth = 0;
        double childHeight = 0;

        ViewGroup.LayoutParams bannerAdViewLP = bannerAdView.getLayoutParams();
        if (bannerChild != null) {
            ViewGroup.LayoutParams temp = bannerAdView.getLayoutParams();
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
