package pl.ukaszapps.fairbid_flutter;

import android.app.Activity;
import android.content.Context;
import android.location.Location;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.fyber.FairBid;
import com.fyber.fairbid.ads.Banner;
import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.ads.Interstitial;
import com.fyber.fairbid.ads.Rewarded;
import com.fyber.fairbid.ads.banner.BannerListener;
import com.fyber.fairbid.ads.banner.BannerOptions;
import com.fyber.fairbid.ads.mediation.MediatedNetwork;
import com.fyber.fairbid.ads.mediation.MediationStartedListener;
import com.fyber.fairbid.ads.rewarded.RewardedOptions;
import com.fyber.fairbid.internal.Constants;
import com.fyber.fairbid.internal.Framework;
import com.fyber.fairbid.user.Gender;
import com.fyber.fairbid.user.UserInfo;


import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformViewRegistry;

interface ValueGetter<T> {
    T get();
}

public final class FairBidFlutterPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin, ActivityAware {
    private static final String TAG = "FairBidFlutter";
    private static final Handler mainThreadHandler = new Handler(Looper.getMainLooper());
    static boolean debugLogging = false;
    private BannerAdsFactory bannerAdFactoryInstance;
    @SuppressWarnings("FieldCanBeLocal")
    private EventChannel eventChannel;
    private EventChannel adapterEventChannel;
    private EventChannel.EventSink eventSink;
    private EventChannel.EventSink adapterEventSink;
    private BannerCreationResultListener resultBannerListener;
    private PlatformViewRegistry platformRegistry;
    private BinaryMessenger messenger;
    private Activity activityRef;
    private Context applicationContext;
    private ValueGetter<Activity> activityGetter;

    @Override
    public void onAttachedToActivity(@NonNull @NotNull ActivityPluginBinding activityPluginBinding) {
        this.activityRef = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activityRef = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull @NotNull ActivityPluginBinding activityPluginBinding) {
        this.activityRef = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.activityRef = null;
    }

    @Override
    public void onAttachedToEngine(@NonNull @NotNull FlutterPluginBinding flutterPluginBinding) {
        Utils.checkParameterIsNotNull(flutterPluginBinding, "flutterPluginBinding");

        this.onInit(flutterPluginBinding.getBinaryMessenger(), flutterPluginBinding.getPlatformViewRegistry(), flutterPluginBinding.getApplicationContext());
        this.activityGetter = () -> activityRef;
    }

    private void onInit(@NonNull BinaryMessenger messenger, @NonNull PlatformViewRegistry registry, @NonNull Context applicationContext) {
        this.platformRegistry = registry;
        this.messenger = messenger;
        this.applicationContext = applicationContext;

        MethodChannel channel = new MethodChannel(messenger, "pl.ukaszapps.fairbid_flutter");
        channel.setMethodCallHandler(this);
        this.platformRegistry.registerViewFactory("bannerView", this.getBannerAdFactory());


        this.adapterEventChannel = new EventChannel(messenger, "pl.ukaszapps.fairbid_flutter:adapterEvents");
        this.adapterEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                adapterEventSink = eventSink;
            }

            @Override
            public void onCancel(Object o) {
                adapterEventSink = null;
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull @NotNull FlutterPluginBinding flutterPluginBinding) {

    }

    public static void registerWith(@NonNull PluginRegistry.Registrar registrar) {
        FairBidFlutterPlugin instance = new FairBidFlutterPlugin();
        instance.onInit(registrar.messenger(), registrar.platformViewRegistry(), registrar.context());
        instance.activityGetter = () -> registrar.activity();

    }

    static void runOnMain(Runnable runnable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run();
        } else {
            mainThreadHandler.post(runnable);
        }
    }

    private BannerAdsFactory getBannerAdFactory() {
        if (bannerAdFactoryInstance == null) {
            bannerAdFactoryInstance = new BannerAdsFactory(messenger);
        }
        return bannerAdFactoryInstance;
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
            FairBid.showTestSuite(activityGetter.get());
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
        } else if (Utils.areEqual(call.method, "getImpressionDepth")) {
            this.invokeGetImpressionDepth(call, result);
        } else if (Utils.areEqual(call.method, "updateCCPA")) {
            this.invokeCCPAStringUpdate(call, result);
        } else if (Utils.areEqual(call.method, "clearCCPA")) {
            this.invokeClearCCPAString(result);
        } else if (Utils.areEqual(call.method, "setMuted")) {
            this.invokeSetMuted(call, result);
        } else if (Utils.areEqual(call.method, "changeAutoRequesting")) {
            this.invokeChangeAutoRequesting(call, result);
        } else if (Utils.areEqual(call.method, "getImpressionData")) {
            this.invokeGetImpressionData(call, result);
        } else {
            result.notImplemented();
        }

    }

    private void invokeGetImpressionData(MethodCall call, MethodChannel.Result result) {
        String type = call.argument("adType");
        String placement = (String) call.argument("placement");
        if ("rewarded".equals(type)) {
            result.success(impressionDataToMap(Rewarded.getImpressionData(placement)));
        } else if ("interstitial".equals(type)) {
            result.success(impressionDataToMap(Interstitial.getImpressionData(placement)));
        } else {
            result.error("INVALID_ARGUMENTS", null, null);
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

            Banner.show(placement, options, activityGetter.get());

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
            resultBannerListener.unregisterCallback(placement);

            sendEvent(Constants.AdType.BANNER, placement, "hide", null);
        }

    }

    private void invokeLoadBanner(MethodCall call, final MethodChannel.Result result) {
        Object args = call.arguments;
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT_WATCH) {
            result.error("Unsupported operation", "Native views are not supported on that API level", "In-view banners require at least Android API 20 (Kitkat Watch)");
        }
        if (args != null) {
            Map<String, Object> arguments = (Map<String, Object>) args;

            final String placement = (String) arguments.get("placement");
            final Integer requestedWidth = (Integer) arguments.get("width");
            final Integer requestedHeight = (Integer) arguments.get("height");
            assert placement != null;

            if (!this.getBannerAdFactory().hasBanner(placement)) {
                if (debugLogging) {
                    Log.d(TAG,
                            "creating banner '" + placement + "' for size (" + requestedWidth + ", " + requestedHeight + ") "
                    );
                }
                resultBannerListener.registerCallback(placement, result);
                this.getBannerAdFactory().createBannerView(activityGetter.get(), placement, requestedWidth, requestedHeight);

            } else {
                runOnMain(() -> {
                    ArrayList<Double> size = BannerAdsFactory.getBannerMeasurements(
                            getBannerAdFactory().get(placement));
                    result.success(size);
                });
            }
        } else {
            result.error("Invalid arguments", "Arguments MUST NOT be empty", null);
        }

    }

    @SuppressWarnings("deprecation")
    private void invokeGetUserData(MethodChannel.Result result) {
        Map<String, Object> userData = new HashMap<>();
        userData.put("gender", UserInfo.getGender().getCode());
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
                if (Utils.areEqual(tempArgument, value.getCode())) {
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

        UserInfo.setUserId(call.argument("id"));

        result.success(null);
    }

    private void invokeClearCCPAString(MethodChannel.Result result) {
        UserInfo.clearIabUsPrivacyString(applicationContext);
        result.success(null);
    }

    private void invokeCCPAStringUpdate(MethodCall call, MethodChannel.Result result) {
        String ccpaString = call.argument("ccpaString");
        UserInfo.setIabUsPrivacyString(ccpaString, applicationContext);
        result.success(null);
    }

    private void invokeClearGDPRString(MethodChannel.Result result) {
        UserInfo.clearGdprConsent(applicationContext);
        result.success(null);
    }

    private void invokeGDPRUpdate(MethodCall call, MethodChannel.Result result) {
        Boolean grantConsent = call.argument("grantConsent");
        if (grantConsent != null) {
            boolean consentGranted = grantConsent;
            UserInfo.setGdprConsent(consentGranted, applicationContext);
        }

        String consentString = call.argument("consentString");
        if (consentString != null) {
            UserInfo.setGdprConsentString(consentString, applicationContext);
        }

        result.success(null);
    }

    private void invokeShow(MethodCall call, MethodChannel.Result result) {
        Activity activity = activityGetter.get();
        if (activity == null){
            result.error("Unable show add - activity not available", null, null);
            return;
        }

        String type = call.argument("adType");

        String placement = call.argument("placement");

        Map<String, String> extraOptions = call.argument("extraOptions");

        assert type != null;
        assert placement != null;

        if ("rewarded".equals(type)) {
            if (extraOptions == null) {
                Rewarded.show(placement, activity);
            } else {
                RewardedOptions options = new RewardedOptions();
                options.setCustomParameters(extraOptions);
                Rewarded.show(placement, options, activity);
            }
        }

        if ("interstitial".equals(type)) {
            if (extraOptions == null) {
                Interstitial.show(placement, activity);
            } else {

                RewardedOptions options = new RewardedOptions();
                options.setCustomParameters(extraOptions);
                Interstitial.show(placement, options, activity);
            }
        }

        result.success(null);
        // resetting state of the placement
        if ("rewarded".equals(type)) {
            sendEvent(Constants.AdType.REWARDED, placement, "unavailable", null);
        }
        if ("interstitial".equals(type)) {
            sendEvent(Constants.AdType.INTERSTITIAL, placement, "unavailable", null);
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
        } else if ("banner".equals(type)) {
            result.success(Banner.getImpressionDepth());
        } else {
            result.error("INVALID_ARGUMENTS", null, null);
        }
    }

    private void invokeSetMuted(MethodCall call, MethodChannel.Result result) {
        boolean mute = call.argument("mute");
        FairBid.Settings.setMuted(mute);
        result.success(null);
    }

    private void invokeChangeAutoRequesting(MethodCall call, MethodChannel.Result result) {
        String type = call.argument("adType");
        String placement = call.argument("placement");
        boolean enableAutoRequesting = call.argument("enable");
        switch (type) {
            case "rewarded":
                if (enableAutoRequesting) {
                    Rewarded.enableAutoRequesting(placement);
                } else {
                    Rewarded.disableAutoRequesting(placement);
                }
                result.success(enableAutoRequesting);
                break;
            case "interstitial":
                if (enableAutoRequesting) {
                    Interstitial.enableAutoRequesting(placement);
                } else {
                    Interstitial.disableAutoRequesting(placement);
                }
                result.success(enableAutoRequesting);
                break;
            default:
                result.notImplemented();
        }
    }

    private void startSdkAndInitListeners(MethodCall call, MethodChannel.Result result) {
        if (FairBid.hasStarted()) {
            result.success(true);
            return;
        }
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
        Framework.framework = "flutter";
        Framework.pluginVersion = call.argument("pluginVersion");

        FairBid sdk = FairBid.configureForAppId(publisherId)
                .withMediationStartedListener(new MediationStartedListener() {
                    @Override
                    public void onNetworkStarted(@NotNull MediatedNetwork mediatedNetwork) {
                        if (debugLogging){
                            Log.d(TAG, "network " + mediatedNetwork.getName()+" ("+mediatedNetwork.getVersion()+") started");
                        }
                        if (adapterEventSink != null) {
                            Map<String, String> message = new HashMap<>();
                            message.put("name", mediatedNetwork.getName());
                            message.put("version", mediatedNetwork.getVersion());
                            adapterEventSink.success(
                                    message
                            );
                        }
                    }

                    @Override
                    public void onNetworkFailedToStart(@NotNull MediatedNetwork mediatedNetwork, @NotNull String errorMessage) {
                        if (debugLogging){
                            Log.d(TAG, "network " + mediatedNetwork.getName()+" ("+mediatedNetwork.getVersion()+") not started:\n"+errorMessage);
                        }
                        if (adapterEventSink != null) {
                            Map<String, String> message = new HashMap<>();
                            message.put("name", mediatedNetwork.getName());
                            message.put("version", mediatedNetwork.getVersion());
                            message.put("message", errorMessage);
                            adapterEventSink.success(
                                    message
                            );
                        }
                    }
                });
        if (!autoRequesting) {
            sdk = sdk.disableAutoRequesting();
        }

        if (debugLogging) {
            sdk = sdk.enableLogs();
        }
        Activity activity = activityGetter.get();
        // starting SDK
        if (activity == null) {
            throw new NullPointerException("Plugin registered outside Activity context");
        }

        sdk.start(activity);

        // setting up the events channel
        this.eventChannel = new EventChannel(messenger, "pl.ukaszapps.fairbid_flutter:events");

        eventChannel.setStreamHandler((new EventChannel.StreamHandler() {
            public void onListen(@Nullable Object arguments, @NonNull EventChannel.EventSink sink) {
                FairBidFlutterPlugin.this.eventSink = sink;
            }

            public void onCancel(@Nullable Object arguments) {
                FairBidFlutterPlugin.this.eventSink = null;
            }
        }));

        // registering callbacks
        EventSender eventSender = ((adType, placementName, eventName, impressionData, extras) -> {
            FairBidFlutterPlugin self = FairBidFlutterPlugin.this;
            self.sendEvent(adType, placementName, eventName, impressionData, extras);
        });
        resultBannerListener = new BannerCreationResultListener();
        Interstitial.setInterstitialListener((new InterstitialEventProducer(eventSender)));
        Rewarded.setRewardedListener((new RewardedEventProducer(eventSender)));
        Banner.setBannerListener(new CombinedBannerListener(new BannerListener[]{new BannerEventProducer(eventSender), resultBannerListener, this.getBannerAdFactory()}));
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
            runOnMain(new Runnable() {
                @Override
                public void run() {
                    sink.success(eventData);
                }
            });
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
        output.put("variantId", impressionData.getVariantId());
        return output;
    }
}
