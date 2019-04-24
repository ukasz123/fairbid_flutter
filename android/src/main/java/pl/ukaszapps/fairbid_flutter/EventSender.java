package pl.ukaszapps.fairbid_flutter;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.fyber.fairbid.ads.ImpressionData;
import com.fyber.fairbid.internal.Constants;

/**
 *
 */
interface EventSender {
    void send(@NonNull Constants.AdType adType, @NonNull String placementName, @NonNull String eventName, @Nullable ImpressionData impressionData, Object... extras) ;
}
