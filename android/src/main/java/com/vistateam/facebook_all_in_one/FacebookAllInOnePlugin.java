package com.vistateam.facebook_all_in_one;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;

import com.facebook.FacebookSdk;
import com.facebook.applinks.AppLinkData;

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
public class FacebookAllInOnePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener,EventChannel.StreamHandler {
    // Channel String;
    private static final String CHANNEL_NAME = "VistaTeam/facebook_all_in_one";
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

    private static final String MESSAGES_CHANNEL = "uni_links/messages";
    private static final String EVENTS_CHANNEL = "uni_links/events";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        this.mContext = flutterPluginBinding.getApplicationContext();
        register(flutterPluginBinding.getFlutterEngine().getDartExecutor(), this);

    }

    private static void register(BinaryMessenger messenger, FacebookAllInOnePlugin plugin) {
        final MethodChannel methodChannel = new MethodChannel(messenger, MESSAGES_CHANNEL);
        methodChannel.setMethodCallHandler(plugin);

        final EventChannel eventChannel = new EventChannel(messenger, EVENTS_CHANNEL);
        eventChannel.setStreamHandler(plugin);
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

    public static void registerWith(PluginRegistry.Registrar registrar) {
        // Detect if we've been launched in background
        if (registrar.activity() == null) {
            return;
        }

        final FacebookAllInOnePlugin instance = new FacebookAllInOnePlugin();
        instance.mContext = registrar.context();
        register(registrar.messenger(), instance);

        instance.handleIntent(registrar.context(), registrar.activity().getIntent());
        registrar.addNewIntentListener(instance);
    }

}
