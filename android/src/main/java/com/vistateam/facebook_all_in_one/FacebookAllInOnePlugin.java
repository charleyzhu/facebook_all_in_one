package com.vistateam.facebook_all_in_one;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;

import com.facebook.FacebookSdk;
import com.facebook.GraphRequest;
import com.facebook.GraphResponse;
import com.facebook.appevents.AppEventsLogger;
import com.facebook.applinks.AppLinkData;
import com.facebook.login.LoginBehavior;

import org.json.JSONObject;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Currency;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FacebookAllInOnePlugin
 */
public class FacebookAllInOnePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    // Channel String;
    private static final String CHANNEL_NAME = "VistaTeam/facebook_all_in_one";
    private static final String ERROR_UNKNOWN_LOGIN_BEHAVIOR = "unknown_login_behavior";
    private static final String LOGIN_BEHAVIOR_NATIVE_WITH_FALLBACK = "nativeWithFallback";
    private static final String LOGIN_BEHAVIOR_NATIVE_ONLY = "nativeOnly";
    private static final String LOGIN_BEHAVIOR_WEB_ONLY = "webOnly";
    private static final String LOGIN_BEHAVIOR_WEB_VIEW_ONLY = "webViewOnly";
    private static final String ARG_LOGIN_BEHAVIOR = "behavior";
    private static final String ARG_PERMISSIONS = "permissions";
    private static final String ARG_FIELDS = "fields";
    private static final String ARG_DEEP_LINK = "deeplink";
    private static final String ARG_PROMOTIONAL_CODE = "promotionalCode";
    private static final String METHOD_DEEP_LINK = "getFBLinks";
    private static final String METHOD_LOG_IN = "login";
    private static final String METHOD_IS_LOGGED = "isLogged";
    private static final String METHOD_GET_USER_DATA = "getUserData";
    private static final String METHOD_LOG_OUT = "logOut";
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context mContext;
    AppEventsLogger appEventsLogger ;
    private Activity mActivity;
    private FacebookAuth facebookAuth = new FacebookAuth();
    private ActivityPluginBinding activityPluginBinding;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        this.mContext = flutterPluginBinding.getApplicationContext();
        appEventsLogger = AppEventsLogger.newLogger(mContext);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals(METHOD_DEEP_LINK)) {
            getFBLinks(call, result);
        } else if (call.method.equals(METHOD_LOG_IN)) {
            List<String> permissions = call.argument(ARG_PERMISSIONS);
            String loginBehaviorStr = call.argument(ARG_LOGIN_BEHAVIOR);
            LoginBehavior loginBehavior = loginBehaviorFromString(loginBehaviorStr, result);
            facebookAuth.login(this.activityPluginBinding.getActivity(), loginBehavior, permissions, result);
        } else if (call.method.equals(METHOD_IS_LOGGED)) {
            facebookAuth.isLogged(result);
        } else if (call.method.equals(METHOD_GET_USER_DATA)) {
            String fields = call.argument(ARG_FIELDS);
            facebookAuth.getUserData(fields, result);
        } else if (call.method.equals(METHOD_LOG_OUT)) {
            facebookAuth.logOut(result);
        } else if (call.method.equals("clearUserData")) {
            handleClearUserData(call, result);
        } else if (call.method.equals("clearUserID")) {
            handleClearUserId(call, result);
        }else if (call.method.equals("flush")) {
            handleFlush(call, result);
        }else if (call.method.equals("getApplicationId")) {
            getApplicationId(call, result);
        }else if (call.method.equals("logEvent")) {
            handleLogEvent(call, result);
        }else if (call.method.equals("logPushNotificationOpen")) {
            handlePushNotificationOpen(call, result);
        }else if (call.method.equals("setUserData")) {
            handleSetUserData(call, result);
        }else if (call.method.equals("setUserID")) {
            handleSetUserId(call, result);
        }else if (call.method.equals("updateUserProperties")) {
            handleUpdateUserProperties(call, result);
        }else if (call.method.equals("setAutoLogAppEventsEnabled")) {
            handleSetAutoLogAppEventsEnabled(call, result);
        }else if (call.method.equals("setDataProcessingOptions")) {
            setDataProcessingOptions(call, result);
        }else if (call.method.equals("logPurchase")) {
            handlePurchased(call, result);
        }else {
            result.notImplemented();
        }
    }

    private void getFBLinks(MethodCall call, Result result) {
        final Map<String, String> data = new HashMap<>();
        final Result resultDelegate = result;
        // Get a handler that can be used to post to the main thread
        final Handler mainHandler = new Handler(mContext.getMainLooper());

        // Get user consent
        FacebookSdk.setAutoInitEnabled(true);
        FacebookSdk.fullyInitialize();
        AppLinkData.fetchDeferredAppLinkData(mContext,
                new AppLinkData.CompletionHandler() {
                    @Override
                    public void onDeferredAppLinkDataFetched(AppLinkData appLinkData) {
                        // Process app link data
                        if (appLinkData != null) {

                            if (appLinkData.getTargetUri() != null) {
                                //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getTargetUri().toString());
                                data.put(ARG_DEEP_LINK, appLinkData.getTargetUri().toString());
                            }

                            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getPromotionCode());
                            if (appLinkData.getPromotionCode() != null)
                                data.put(ARG_PROMOTIONAL_CODE, appLinkData.getPromotionCode());
                            else
                                data.put(ARG_PROMOTIONAL_CODE, "");

                            Runnable myRunnable = new Runnable() {
                                @Override
                                public void run() {
                                    if (resultDelegate != null)
                                        resultDelegate.success(data);
                                }
                            };

                            mainHandler.post(myRunnable);

                        } else {
                            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: null link");

                            Runnable myRunnable = new Runnable() {
                                @Override
                                public void run() {
                                    if (resultDelegate != null)
                                        resultDelegate.success(null);
                                }
                            };

                            mainHandler.post(myRunnable);

                        }

                    }
                }
        );
    }


    private void attachToActivity(ActivityPluginBinding binding) {
        this.activityPluginBinding = binding;
        activityPluginBinding.addActivityResultListener(facebookAuth.resultDelegate);
    }

    private void disposeActivity() {
        activityPluginBinding.removeActivityResultListener(facebookAuth.resultDelegate);
        // delegate.setActivity(null);
        activityPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.attachToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        disposeActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.attachToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        disposeActivity();
    }

    private LoginBehavior loginBehaviorFromString(String loginBehavior, Result result) {
        switch (loginBehavior) {
            case LOGIN_BEHAVIOR_NATIVE_WITH_FALLBACK:
                return LoginBehavior.NATIVE_WITH_FALLBACK;
            case LOGIN_BEHAVIOR_NATIVE_ONLY:
                return LoginBehavior.NATIVE_ONLY;
            case LOGIN_BEHAVIOR_WEB_ONLY:
                return LoginBehavior.WEB_ONLY;
            case LOGIN_BEHAVIOR_WEB_VIEW_ONLY:
                return LoginBehavior.WEB_VIEW_ONLY;
            default:
                result.error(
                        ERROR_UNKNOWN_LOGIN_BEHAVIOR,
                        "setLoginBehavior called with unknown login behavior: "
                                + loginBehavior,
                        null
                );
                return null;
        }
    }

    private void handleClearUserData(MethodCall call, Result result) {
        AppEventsLogger.clearUserData();
        result.success(null);
    }

    private void handleClearUserId(MethodCall call, Result result) {
        AppEventsLogger.clearUserID();
        result.success(null);
    }

    private void handleFlush(MethodCall call, Result result) {
        appEventsLogger.flush();
        result.success(null);
    }

    private void getApplicationId(MethodCall call, Result result) {
        result.success(appEventsLogger.getApplicationId());
    }

    private void handleLogEvent(MethodCall call, Result result) {
        String eventName = call.argument("name");
        Map<String, Object> parameters = call.argument("parameters");
        Double valueToSum = call.argument("_valueToSum");

        if (valueToSum != null && parameters != null) {
            Bundle parameterBundle = createBundleFromMap(parameters);
            appEventsLogger.logEvent(eventName, valueToSum, parameterBundle);
        } else if (valueToSum != null) {
            appEventsLogger.logEvent(eventName, valueToSum);
        } else if (parameters != null) {
            Bundle parameterBundle = createBundleFromMap(parameters);
            appEventsLogger.logEvent(eventName, parameterBundle);
        } else {
            appEventsLogger.logEvent(eventName);
        }

        result.success(null);
    }

    private void handlePushNotificationOpen(MethodCall call, Result result) {
        String action = call.argument("action");
        Map<String, Object> payload = call.argument("payload");
        Bundle payloadBundle = createBundleFromMap(payload);

        if (action != null) {
            appEventsLogger.logPushNotificationOpen(payloadBundle, action);
        } else {
            appEventsLogger.logPushNotificationOpen(payloadBundle);
        }

        result.success(null);
    }

    private void handleSetUserData(MethodCall call, Result result) {
        Map<String, Object> parameters = call.argument("parameters");
        Bundle parameterBundle = createBundleFromMap(parameters);

        if (parameterBundle != null) {
            AppEventsLogger.setUserData(parameterBundle.getString("email")
                    , parameterBundle.getString("firstName")
                    , parameterBundle.getString("lastName")
                    , parameterBundle.getString("phone")
                    , parameterBundle.getString("dateOfBirth")
                    , parameterBundle.getString("gender")
                    , parameterBundle.getString("city")
                    , parameterBundle.getString("state")
                    , parameterBundle.getString("zip")
                    , parameterBundle.getString("country"));
        }


        result.success(null);
    }

    private void handleUpdateUserProperties(MethodCall call, final Result result) {
        String applicationId = call.argument("applicationId");
        Map<String, Object> parameters = call.argument("parameters");
        Bundle parameterBundle = createBundleFromMap(parameters);

        GraphRequest.Callback requestCallback = new GraphRequest.Callback() {
            @Override
            public void onCompleted(GraphResponse response) {
                JSONObject data = response.getJSONObject();
                result.success(data);
            }
        };

        if (applicationId == null)
            AppEventsLogger.updateUserProperties(parameterBundle, requestCallback);
        else AppEventsLogger.updateUserProperties(parameterBundle, applicationId, requestCallback);

        result.success(null);
    }

    private void handleSetUserId(MethodCall call, Result result) {
        String id = (String) call.arguments;
        AppEventsLogger.setUserID(id);
        result.success(null);
    }

    private Bundle createBundleFromMap(Map<String, Object> parameterMap) {
        if (parameterMap == null) {
            return null;
        }

        Bundle bundle = new Bundle();

        Iterator entries = parameterMap.entrySet().iterator();
        while (entries.hasNext()) {
            Map.Entry entry = (Map.Entry) entries.next();
            Object value = entry.getValue();
            String key = (String) entry.getKey();
            if (value instanceof String) {
                bundle.putString(key, String.valueOf(value));
            } else if (value instanceof Integer) {
                bundle.putInt(key, (Integer) value);
            } else if (value instanceof Long) {
                bundle.putLong(key, (Long) value);
            } else if (value instanceof Double) {
                bundle.putDouble(key, (Double) value);
            } else if (value instanceof Boolean) {
                bundle.putBoolean(key, (Boolean) value);
            } else if (value instanceof Map) {
                Bundle nestedBundle = createBundleFromMap((Map<String, Object>) value);
                bundle.putBundle(key, nestedBundle);
            } else {
                throw new IllegalArgumentException(
                        "Unsupported value type: ");
            }

        }

        return bundle;
    }

    private void handleSetAutoLogAppEventsEnabled(MethodCall call, Result result) {
        Boolean enabled = (Boolean) call.arguments;
        FacebookSdk.setAutoLogAppEventsEnabled(enabled);
        result.success(null);
    }

    private void setDataProcessingOptions(MethodCall call, Result result) {
        ArrayList<String> options = call.argument("options");
        Object countryObject = call.argument("country");
        int country = countryObject instanceof Integer ? (int) countryObject : 0;
        Object stateObject = call.argument("state");
        int state = stateObject instanceof Integer ? (int) stateObject : 0;

        FacebookSdk.setDataProcessingOptions((String[]) options.toArray(), country, state);
        result.success(null);
    }

    private void handlePurchased(MethodCall call, Result result) {
        Object amountObject = call.argument("amount");
        Double amount = amountObject instanceof Double ? (Double) amountObject : 0;

        Currency currency = Currency.getInstance(String.valueOf(call.argument("currency")));
        Map<String, Object> parameters = call.argument("parameters");
        Bundle parameterBundle = createBundleFromMap(parameters);

        appEventsLogger.logPurchase(BigDecimal.valueOf(amount), currency, parameterBundle);
        result.success(null);
    }

}
