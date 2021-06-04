package com.vistateam.facebook_all_in_one;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;

import com.facebook.FacebookSdk;
import com.facebook.appevents.AppEventsLogger;
import com.facebook.applinks.AppLinkData;
import com.google.android.gms.ads.identifier.AdvertisingIdClient;

import java.math.BigDecimal;
import java.util.Currency;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FacebookAllInOnePlugin
 */
public class FacebookAllInOnePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener, EventChannel.StreamHandler {
    // Channel String;
    private static final String CHANNEL_NAME = "VistaTeam/facebook_all_in_one";
    private static final String MESSAGES_CHANNEL = "uni_links/messages";
    private static final String EVENTS_CHANNEL = "uni_links/events";
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context mContext;
    private Activity mActivity;
    private FacebookAuth facebookAuth = new FacebookAuth();
    private ActivityPluginBinding activityPluginBinding;
    private String initialLink;
    private String latestLink;
    private boolean initialIntent = true;
    private BroadcastReceiver changeReceiver;
    private AppEventsLogger appEventsLogger;

    private static void register(BinaryMessenger messenger, FacebookAllInOnePlugin plugin) {
        final MethodChannel methodChannel = new MethodChannel(messenger, MESSAGES_CHANNEL);
        methodChannel.setMethodCallHandler(plugin);

        final EventChannel eventChannel = new EventChannel(messenger, EVENTS_CHANNEL);
        eventChannel.setStreamHandler(plugin);
    }

    public static void registerWith(PluginRegistry.Registrar registrar) {
        // Detect if we've been launched in background
        if (registrar.activity() == null) {
            return;
        }

        final FacebookAllInOnePlugin instance = new FacebookAllInOnePlugin();
        instance.mContext = registrar.context();
        instance.mActivity = registrar.activity();
        register(registrar.messenger(), instance);

        instance.handleIntent(registrar.context(), registrar.activity().getIntent());
        registrar.addNewIntentListener(instance);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        this.mContext = flutterPluginBinding.getApplicationContext();
        register(flutterPluginBinding.getFlutterEngine().getDartExecutor(), this);
        appEventsLogger = AppEventsLogger.newLogger(flutterPluginBinding.getApplicationContext());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("getFBLinks")) {
            getFBLinks(call, result);
        } else if (call.method.equals("login")) {
            List<String> permissions = call.argument("permissions");
            facebookAuth.login(this.activityPluginBinding.getActivity(), permissions, result);
        } else if (call.method.equals("isLogged")) {
            facebookAuth.isLogged(result);
        } else if (call.method.equals("getUserData")) {
            String fields = call.argument("fields");
            facebookAuth.getUserData(fields, result);
        } else if (call.method.equals("logOut")) {
            facebookAuth.logOut(result);
        } else if (call.method.equals("getLaunchingLink")) {
            result.success(initialLink);
        } else if (call.method.equals("logPurchase")) {
            logPurchase(call, result);
        } else if (call.method.equals("logEvent")) {
            handleLogEvent(call, result);
        }else if (call.method.equals("getAdvertisingId")) {
            getAdvertisingId(call, result);
        }else if (call.method.equals("isLimitAdTrackingEnabled")) {
            isLimitAdTrackingEnabled(call, result);
        } else {
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
                                data.put("deeplink", appLinkData.getTargetUri().toString());
                            }

                            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getPromotionCode());
                            if (appLinkData.getPromotionCode() != null)
                                data.put("promotionalCode", appLinkData.getPromotionCode());
                            else
                                data.put("promotionalCode", "");

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

    private void handleLogEvent(MethodCall call,Result result) {
        String eventName = call.argument("name");
        Map<String,Object> parameters = call.argument("parameters");
        Boolean isValueToSumExist = call.hasArgument("_valueToSum");

        if (isValueToSumExist && parameters != null) {
            Bundle parameterBundle = createBundleFromMap(parameters);
            double valueToSum = call.argument("_valueToSum");
            appEventsLogger.logEvent(eventName, valueToSum,parameterBundle);
        }else if (isValueToSumExist) {
            double valueToSum = call.argument("_valueToSum");
            appEventsLogger.logEvent(eventName, valueToSum);
        }else if (parameters != null) {
            Bundle parameterBundle = createBundleFromMap(parameters);
            appEventsLogger.logEvent(eventName, parameterBundle);
        }else {
            appEventsLogger.logEvent(eventName);
        }
    }

    private void getAdvertisingId(MethodCall call, final Result result) {
        if (this.mActivity == null) {
            result.error("400","get Activity Error",null);
        }else {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        final String id = AdvertisingIdClient.getAdvertisingIdInfo(mActivity).getId();
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(id);
                            }
                        });

                    }catch (final Exception e) {
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                result.error(e.getClass().getCanonicalName(),e.getLocalizedMessage(),null);
                            }
                        });

                    }


                }
            }).start();

        }

    }

    private void isLimitAdTrackingEnabled(MethodCall call, final Result result) {
        if (this.mActivity == null) {
            result.error("400","get Activity Error",null);
        }else {

            new Thread(new Runnable() {
                @Override
                public void run() {

                    try {
                        final boolean isLimitAdTrackingEnabled = AdvertisingIdClient.getAdvertisingIdInfo(mActivity).isLimitAdTrackingEnabled();
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(isLimitAdTrackingEnabled);
                            }
                        });
                    }catch (final Exception e) {
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                result.error(e.getClass().getCanonicalName(),e.getLocalizedMessage(),null);
                            }
                        });
                    }
                }
            }).start();


        }
    }

    private void logPurchase(MethodCall call, Result result) {

        Double amountD = call.argument("amount");
        BigDecimal amount = BigDecimal.valueOf(0);
        if (amountD != null) {
            amount = BigDecimal.valueOf(amountD);
        }

        Currency currency = Currency.getInstance((String) call.argument("currency"));

        Map<String, Object> parameters = call.argument("parameters");
        Bundle parameterBundle = null;
        if (parameters != null) {
            parameterBundle = createBundleFromMap(parameters);
        }


        appEventsLogger.logPurchase(amount, currency, parameterBundle);

        result.success(null);
    }

    private Bundle createBundleFromMap(Map<String, Object> parameters) {
        Bundle bundle = new Bundle();

        for (String key : parameters.keySet()) {
            Object value = parameters.get(key);
            if (value instanceof String) {
                bundle.putString(key, (String) value);
            } else if (value instanceof Integer) {
                bundle.putInt(key, (Integer) value);
            } else if (value instanceof Long) {
                bundle.putLong(key, (Long) value);
            } else if (value instanceof Double) {
                bundle.putDouble(key, (Double) value);
            } else if (value instanceof Boolean) {
                bundle.putBoolean(key, (Boolean) value);
            } else {
                throw new IllegalArgumentException("Unsupported value type: " + value);
            }
        }

        return bundle;
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
        activityPluginBinding.addOnNewIntentListener(this);
        this.handleIntent(this.mContext, activityPluginBinding.getActivity().getIntent());
        mActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        disposeActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.attachToActivity(binding);
        activityPluginBinding.addOnNewIntentListener(this);
        this.handleIntent(this.mContext, activityPluginBinding.getActivity().getIntent());
    }

    @Override
    public void onDetachedFromActivity() {
        disposeActivity();
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        this.handleIntent(mContext, intent);
        return false;
    }

    private void handleIntent(Context context, Intent intent) {
        String action = intent.getAction();
        String dataString = intent.getDataString();

        if (Intent.ACTION_VIEW.equals(action)) {
            if (initialIntent) {
                initialLink = dataString;
                initialIntent = false;
            }
            latestLink = dataString;
            if (changeReceiver != null) changeReceiver.onReceive(context, intent);
        }
    }

    private BroadcastReceiver createChangeReceiver(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                // NOTE: assuming intent.getAction() is Intent.ACTION_VIEW

                // Log.v("uni_links", String.format("received action: %s", intent.getAction()));

                String dataString = intent.getDataString();

                if (dataString == null) {
                    events.error("UNAVAILABLE", "Link unavailable", null);
                } else {
                    events.success(dataString);
                }
            }
        };
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        changeReceiver = createChangeReceiver(events);
    }

    @Override
    public void onCancel(Object arguments) {
        changeReceiver = null;
    }

}
