package pl.ukaszapps.fairbid_flutter;

import android.content.Context;
import android.content.res.Configuration;

import androidx.annotation.NonNull;

final class Utils {
    public static void checkParameterIsNotNull(Object value, String paramName) {
        if (value == null) {
            throwParameterIsNullException(paramName);
        }
    }

    private static void throwParameterIsNullException(String paramName) {
        StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();

        // #0 Thread.getStackTrace()
        // #1 Intrinsics.throwParameterIsNullException
        // #2 Intrinsics.checkParameterIsNotNull
        // #3 our caller
        StackTraceElement caller = stackTraceElements[3];
        String className = caller.getClassName();
        String methodName = caller.getMethodName();

        IllegalArgumentException exception =
                new IllegalArgumentException("Parameter specified as non-null is null: " +
                        "method " + className + "." + methodName +
                        ", parameter " + paramName);
        throw exception;
    }

    public static <T> boolean  areEqual(T first, T second){
        return first == null ? second == null : first.equals(second);
    }


    /**
     * Determine if the device is a tablet (i.e. it has a large screen).
     *
     * @param context The calling context.
     */
    public static boolean isTablet(@NonNull Context context) {
        return (context.getResources().getConfiguration().screenLayout
                & Configuration.SCREENLAYOUT_SIZE_MASK)
                >= Configuration.SCREENLAYOUT_SIZE_LARGE;
    }

}
