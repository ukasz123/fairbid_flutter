package pl.ukaszapps.fairbid_flutter;

import android.app.Activity;
import android.location.Location;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.fyber.FairBid;
import com.fyber.fairbid.ads.Banner;
import com.fyber.fairbid.ads.CreativeSize;
import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.Interstitial;
import com.fyber.fairbid.ads.Rewarded;
import com.fyber.fairbid.ads.banner.BannerAdView;
import com.fyber.fairbid.ads.banner.BannerError;
import com.fyber.fairbid.ads.banner.BannerListener;
import com.fyber.fairbid.ads.banner.BannerOptions;
import com.fyber.fairbid.ads.rewarded.RewardedOptions;
import com.fyber.fairbid.internal.Constants;
import com.fyber.fairbid.user.Gender;
import com.fyber.fairbid.user.UserInfo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import static com.fyber.fairbid.ads.CreativeSize.SMART_BANNER;

public final class FairBidFlutterPlugin implements MethodChannel.MethodCallHandler {
    private BannerAdsFactory bannerAdFactoryInstance;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private final PluginRegistry.Registrar registrar;
    private static final String TAG = "FairBidFlutter";
    static boolean debugLogging = false;

    private final Handler mainThreadHandler = new Handler(Looper.getMainLooper());

    public static void registerWith(@NonNull PluginRegistry.Registrar registrar) {
        FairBidFlutterPlugin instance = new FairBidFlutterPlugin(registrar);
        MethodChannel channel = new MethodChannel(registrar.messenger(), "pl.ukaszapps.fairbid_flutter");
        channel.setMethodCallHandler(instance);
        registrar.platformViewRegistry().registerViewFactory("bannerView", instance.getBannerAdFactory());
    }

    private BannerAdsFactory getBannerAdFactory() {
        if (bannerAdFactoryInstance == null) {
            bannerAdFactoryInstance = new BannerAdsFactory(this.registrar.messenger(), this.registrar.context().getApplicationContext());
        }
        return bannerAdFactoryInstance;
    }

    public FairBidFlutterPlugin(@NonNull PluginRegistry.Registrar registrar) {
        Utils.checkParameterIsNotNull(registrar, "registrar");
        this.registrar = registrar;
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Utils.checkParameterIsNotNull(call, "call");
        Utils.checkParameterIsNotNull(result, "result");
        if (debugLogging) {
            Log.d(TAG, "onMethodCall(" + call.method + "): " + call.arguments);
        }
        if (Utils.areEqual(call.method, "getPlatformVersion")) {
            result.success(FairBid.SDK_VERSION);
        } else if (Utils.areEqual(call.method, "startSdk")) {
            this.startSdkAndInitListeners(call, result);
        } else if (Utils.areEqual(call.method, "isAvailable")) {
            this.checkAvailability(call, result);
        } else if (Utils.areEqual(call.method, "request")) {
            this.invokeRequest(call, result);
        } else if (Utils.areEqual(call.method, "show")) {
            this.invokeShow(call, result);
        } else if (Utils.areEqual(call.method, "showTestSuite")) {
            FairBid.showTestSuite(this.registrar.activity());
        } else if (Utils.areEqual(call.method, "updateGDPR")) {
            this.invokeGDPRUpdate(call, result);
        } else if (Utils.areEqual(call.method, "clearGDPR")) {
            this.invokeClearGDPRString(result);
        } else if (Utils.areEqual(call.method, "getUserData")) {
            this.invokeGetUserData(result);
        } else if (Utils.areEqual(call.method, "updateUserData")) {
            this.invokeUpdateUser(call, result);
        } else if (Utils.areEqual(call.method, "loadBanner")) {
            this.invokeLoadBanner(call, result);
        } else if (Utils.areEqual(call.method, "destroyBanner")) {
            this.invokeDestroyBanner(call);
        } else if (Utils.areEqual(call.method, "showAlignedBanner")) {
            this.invokeShowAlignedBanner(call, result);
        } else if (Utils.areEqual(call.method, "destroyAlignedBanner")) {
            this.invokeDestroyAlignedBanner(call, result);
        } else if (Utils.areEqual(call.method, "getImpressionDepth")){
            this.invokeGetImpressionDepth(call, result);
        } else {
            result.notImplemented();
        }

    }

    private void invokeDestroyAlignedBanner(MethodCall call, MethodChannel.Result result) {
        Object args = call.arguments;
        if (args != null) {

            Map arguments = (Map) args;

            String placement = (String) arguments.get("placement");
            assert placement != null;
            Banner.destroy(placement);
            sendEvent(Constants.AdType.BANNER, placement, "hide", null);
        }
        result.success(null);
    }

    private void invokeShowAlignedBanner(MethodCall call, MethodChannel.Result result) {
        Object args = call.arguments;
        if (args != null) {

            Map arguments = (Map) args;

            String placement = (String) arguments.get("placement");
            String alignment = (String) arguments.get("alignment");
            assert placement != null;
            assert alignment != null;
            BannerOptions options = new BannerOptions();
            if (alignment.equalsIgnoreCase("top")) {
                options = options.placeAtTheTop();
            } else {
                options = options.placeAtTheBottom();
            }

            Banner.show(placement, options, registrar.activity());

        }
        result.success(null);
    }

    private void invokeDestroyBanner(MethodCall call) {
        Object args = call.arguments;
        if (args != null) {

            Map arguments = (Map) args;

            String placement = (String) arguments.get("placement");
            assert placement != null;
            this.getBannerAdFactory().set(placement, null);

            sendEvent(Constants.AdType.BANNER, placement, "hide", null);
        }

    }

    private void invokeLoadBanner(MethodCall call, final MethodChannel.Result result) {
        Object args = call.arguments;
        Activity activity = this.registrar.activity();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT_WATCH) {
            result.error("Native views are not supported on that API level", null, null);
        }
        if (args != null) {
            Map arguments = (Map) args;

            String placement = (String) arguments.get("placement");
            assert placement != null;
            int placementId = Integer.parseInt(placement);
            final Integer requestedWidth = (Integer) arguments.get("width");
            final Integer requestedHeight = (Integer) arguments.get("height");
            if (debugLogging) {
                Log.d(TAG, "creating banner '" + placement + "' for size (" + requestedWidth + ", " + requestedHeight + ") ");
            }
            final BannerAdView bannerView = new BannerAdView(activity, placementId);
            bannerView.setBackgroundResource(android.R.color.transparent);
            final BannerOptions bannerOptions = new BannerOptions();
            CreativeSize.Builder sizeBuilder = CreativeSize.Builder.newBuilder();
            int tempWidth = ViewGroup.LayoutParams.MATCH_PARENT;
            if (requestedWidth != null) {
                tempWidth = ((Number) (requestedWidth)).intValue();
                sizeBuilder.withWidth(tempWidth);
            }
            int tempHeight = ViewGroup.LayoutParams.MATCH_PARENT ;
            if (requestedHeight != null) {
                tempHeight = ((Number) (requestedHeight)).intValue();
                sizeBuilder.withHeight(tempHeight);
            }

            bannerView.setBannerOptions(bannerOptions.setFallbackSize(SMART_BANNER));
            FrameLayout bannerFrame = new FrameLayout(activity );
            ViewGroup.LayoutParams bannerFrameLayoutParams = new ViewGroup.LayoutParams(tempWidth, tempHeight);
            bannerFrame.setLayoutParams(bannerFrameLayoutParams);
            bannerOptions.placeInContainer(bannerFrame);
            Log.d(TAG, String.format("placing banner in the frame (%d, %d)", tempWidth, tempHeight));
            bannerView.setBannerListener(
                    new BannerListener() {
                        @Override
                        public void onError(@NonNull final String placement, final BannerError bannerError) {
                            runOnMain(new Runnable() {
                                @Override
                                public void run() {
                                    result.error(
                                            (bannerError.getFailure() != null) ? bannerError.getFailure().name() : "unknown",
                                            (bannerError.getErrorMessage() != null) ? bannerError.getErrorMessage() : "no message",
                                            null
                                    );
//                                    sendEvent(Constants.AdType.BANNER, placement, "error", null, bannerError.getErrorMessage());
                                }
                            });
                        }

                        @Override
                        public void onLoad(@NonNull final String placement) {
                            runOnMain(new Runnable() {
                                @Override
                                public void run() {
                                    ArrayList<Double> size = BannerAdsFactory.getBannerMeasurements(bannerView);
                                    result.success(size);
//                                    sendEvent(Constants.AdType.BANNER, placement, "load", null);
                                }
                            });
                        }

                        @Override
                        public void onShow(@NonNull String placement, @NonNull ImpressionData impressionData) {
                            sendEvent(Constants.AdType.BANNER, placement, "show", impressionData);
                        }

                        @Override
                        public void onClick(@NonNull String placement) {

                            sendEvent(Constants.AdType.BANNER, placement, "click", null);
                        }

                        @Override
                        public void onRequestStart(@NonNull String placement) {
                            sendEvent(Constants.AdType.BANNER, placement, "request", null);
                        }
                    }
            );
            bannerView.load(placementId, true);
            this.getBannerAdFactory().set(placement, bannerView);
        } else {
            result.error("Invalid arguments", "Arguments MUST NOT be empty", null);
        }

    }

    @SuppressWarnings("deprecation")
    private void invokeGetUserData(MethodChannel.Result result) {
        Map<String, Object> userData = new HashMap<>();
        userData.put("gender", UserInfo.getGender().code);
        userData.put("id", UserInfo.getUserId());

        Date birthDate = UserInfo.getBirthDate();
        if (birthDate != null) {
            Map<String, Integer> birthdayMap = new HashMap<>();
            birthdayMap.put("year", birthDate.getYear() + 1900);
            birthdayMap.put("month", birthDate.getMonth());
            birthdayMap.put("day", birthDate.getDate());
            userData.put("birthday", birthdayMap);
        }

        Location location = UserInfo.getLocation();
        if (location != null) {
            Map<String, Double> locationMap = new HashMap<>();
            locationMap.put("latitude", location.getLatitude());
            locationMap.put("longitude", location.getLongitude());
            userData.put("location", locationMap);
        }

        result.success(userData);
    }

    private void invokeUpdateUser(MethodCall call, MethodChannel.Result result) {

        String tempArgument = call.argument("gender");
        Gender gender = Gender.UNKNOWN;
        if (tempArgument != null) {
            Gender[] values = Gender.values();

            for (Gender value : values) {
                if (Utils.areEqual(tempArgument, value.code)) {
                    gender = value;
                    break;
                }
            }
        }
        UserInfo.setGender(gender);

        Map<String, Integer> birthdayData = call.argument("birthday");
        Date birthDate;
        if (birthdayData != null) {
            //noinspection deprecation
            birthDate = new Date(birthdayData.get("year") - 1900, birthdayData.get("month"), birthdayData.get("day"));
        } else {
            birthDate = null;
        }

        UserInfo.setBirthDate(birthDate);

        Map<String, Double> locationData = call.argument("location");
        Location location;
        if (locationData != null) {
            location = new Location("FairBid_Flutter");
            location.setLatitude(locationData.get("latitude"));
            location.setLongitude(locationData.get("longitude"));
        } else {
            location = null;
        }

        UserInfo.setLocation(location);

        UserInfo.setUserId((String) call.argument("id"));

        result.success(null);
    }

    private void invokeClearGDPRString(MethodChannel.Result result) {
        UserInfo.clearGdprConsent(this.registrar.activeContext());
        result.success(null);
    }

    private void invokeGDPRUpdate(MethodCall call, MethodChannel.Result result) {
        Boolean grantConsent = call.argument("grantConsent");
        if (grantConsent == null) {
            grantConsent = false;
        }

        boolean consentGranted = grantConsent;
        UserInfo.setGdprConsent(consentGranted, this.registrar.activeContext());

        String consentString = call.argument("consentString");
        if (consentString != null) {
            UserInfo.setGdprConsentString(consentString, this.registrar.activeContext());
        }

        result.success(null);
    }

    private void invokeShow(MethodCall call, MethodChannel.Result result) {

        String type = call.argument("adType");

        String placement = call.argument("placement");

        Map<String, String> extraOptions = call.argument("extraOptions");

        assert type != null;
        assert placement != null;

        if ("rewarded".equals(type)) {
            if (extraOptions == null) {
                Rewarded.show(placement, this.registrar.activity());
            } else {
                RewardedOptions options = new RewardedOptions();
                options.setCustomParameters(extraOptions);
                Rewarded.show(placement, options, this.registrar.activity());
            }
        }

        if ("interstitial".equals(type)) {
            Interstitial.show(placement, this.registrar.activity());
        }

        result.success(null);
        // resetting state of the placement
        if ("rewarded".equals(type)) {
            sendEvent(Constants.AdType.REWARDED, placement, "unavailable", null);
        }
        if ("interstitial".equals(type)) {
            sendEvent(Constants.AdType.INTERSTITIAL, placement, "unavailable",null);
        }


    }

    private void invokeRequest(MethodCall call, MethodChannel.Result result) {
        String type = call.argument("adType");

        String placement = call.argument("placement");

        assert type != null;
        assert placement != null;

        if ("rewarded".equals(type)) {
            Rewarded.request(placement);
        }

        if ("interstitial".equals(type)) {
            Interstitial.request(placement);
        }

        result.success(null);
    }

    private void checkAvailability(MethodCall call, MethodChannel.Result result) {
        String type = call.argument("adType");

        String placement = call.argument("placement");

        assert type != null;
        assert placement != null;

        boolean available = false;
        if ("rewarded".equals(type)) {
            available = Rewarded.isAvailable(placement);
            sendEvent(Constants.AdType.REWARDED, placement, available ? "available" : "unavailable", null);
        }

        if ("interstitial".equals(type)) {
            available = Interstitial.isAvailable(placement);
            sendEvent(Constants.AdType.INTERSTITIAL, placement, available ? "available" : "unavailable", null);

        }

        if (debugLogging) {
            Log.d(TAG, type + '[' + placement + "] is " + (available ? "" : "not ") + "available");
        }
        result.success(available);
    }

    private void invokeGetImpressionDepth(MethodCall call, MethodChannel.Result result) {
        String type = call.argument("adType");
        if ("rewarded".equals(type)) {
            result.success(Rewarded.getImpressionDepth());
        } else if ("interstitial".equals(type)) {
            result.success(Interstitial.getImpressionDepth());
        } else if ("banner".equals(type)){
            result.success(Banner.getImpressionDepth());
        } else {
            result.error("INVALID_ARGUMENTS", null, null);
        }
    }

    private void startSdkAndInitListeners(MethodCall call, MethodChannel.Result result) {
        String publisherId = call.argument("publisherId");
        if (publisherId == null) {
            throw new NullPointerException("'publisherId' cannot be null");
        }
        Boolean tempFlag = call.argument("autoRequesting");
        if (tempFlag == null) {
            tempFlag = true;
        }

        boolean autoRequesting = tempFlag;

        tempFlag = call.argument("logging");
        if (tempFlag == null) {
            tempFlag = false;
        }

        debugLogging = tempFlag;

        FairBid sdk = FairBid.configureForAppId(publisherId);
        if (!autoRequesting) {
            sdk = sdk.disableAutoRequesting();
        }

        if (debugLogging) {
            sdk = sdk.enableLogs();
        }

        // starting SDK
        Activity activity = this.registrar.activity();
        if (activity == null) {
            throw new NullPointerException("Plugin registered outside Activity context");
        }

        sdk.start(activity);

        // setting up the events channel
        this.eventChannel = new EventChannel(this.registrar.messenger(), "pl.ukaszapps.fairbid_flutter:events");

        eventChannel.setStreamHandler((new EventChannel.StreamHandler() {
            public void onListen(@Nullable Object arguments, @NonNull EventChannel.EventSink sink) {
                FairBidFlutterPlugin.this.eventSink = sink;
            }

            public void onCancel(@Nullable Object arguments) {
                FairBidFlutterPlugin.this.eventSink = null;
            }
        }));

        // registering callbacks
        EventSender eventSender = (new EventSender() {
            public final void send(@NonNull Constants.AdType adType, @NonNull String placementName, @NonNull String eventName, @Nullable ImpressionData impressionData, Object[] extras) {
                FairBidFlutterPlugin self = FairBidFlutterPlugin.this;
                self.sendEvent(adType, placementName, eventName, impressionData, extras);
            }
        });
        Interstitial.setInterstitialListener((new InterstitialEventProducer(eventSender)));
        Rewarded.setRewardedListener((new RewardedEventProducer(eventSender)));
        Banner.setBannerListener(new BannerEventProducer(eventSender));
        result.success(true);
    }

    private void sendEvent(@NonNull Constants.AdType adType, @NonNull String placement, @NonNull String eventName, @Nullable ImpressionData impressionData, Object... extras) {
        final EventChannel.EventSink sink = this.eventSink;
        if (debugLogging) {
            Log.d(TAG, "event [" + adType.name() + "](" + placement + "): " + eventName + " { " + Arrays.toString(extras) + " }");
        }
        if (sink != null) {
            final ArrayList<Object> eventData = new ArrayList<>();
            eventData.add(0, adType.name().toLowerCase());
            eventData.add(1, placement);
            eventData.add(2, eventName);
            eventData.add(3, impressionDataToMap(impressionData));
            if (extras != null) {
                eventData.addAll(Arrays.asList(extras));
            }
            runOnMain(new Runnable(){
                @Override
                public void run() {
                    sink.success(eventData);
                }
            });
        }

    }

    private void runOnMain(Runnable runnable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run();
        } else {
            mainThreadHandler.post(runnable);
        }
    }

    private @Nullable
    Map<String, Object> impressionDataToMap(@Nullable ImpressionData impressionData) {
        if (impressionData == null) {
            return null;
        }
        HashMap<String, Object> output = new HashMap<>();
        output.put("netPayout", impressionData.getNetPayout());
        output.put("impressionId", impressionData.getImpressionId());
        output.put("advertiserDomain", impressionData.getAdvertiserDomain());
        output.put("campaignId", impressionData.getCampaignId());
        output.put("countryCode", impressionData.getCountryCode());
        output.put("creativeId", impressionData.getCreativeId());
        output.put("currency", impressionData.getCurrency());
        output.put("demandSource", impressionData.getDemandSource());
        output.put("networkInstanceId", impressionData.getNetworkInstanceId());
        output.put("renderingSdk", impressionData.getRenderingSdk());
        output.put("renderingSdkVersion", impressionData.getRenderingSdkVersion());
        output.put("priceAccuracy", impressionData.getPriceAccuracy().name().toLowerCase(Locale.US));
        output.put("impressionDepth", impressionData.getImpressionDepth());
        return output;
    }

}