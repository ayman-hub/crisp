package com.alaminkarno.flutter_crisp_chat;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.alaminkarno.flutter_crisp_chat.config.CrispConfig;

import java.util.HashMap;
import java.util.List;
import java.util.Locale;

import im.crisp.client.external.ChatActivity;
import im.crisp.client.external.Crisp;
import im.crisp.client.external.data.SessionEvent.Color;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterCrispChatPlugin
 */
public class FlutterCrispChatPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    private static final String CHANNEL_NAME = "flutter_crisp_chat";

    private MethodChannel channel;
    private Context context;
    private Activity activity;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("openCrispChat")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;
            if (args != null) {
                CrispConfig config = CrispConfig.fromJson(args);
                if (config.tokenId != null) {
                    Crisp.configure(context, config.websiteId, config.tokenId);
                } else {
                    Crisp.configure(context, config.websiteId);
                }

                Crisp.enableNotifications(context, config.enableNotifications);
                setCrispData(context, config);
                openActivity();
                result.success(null);
            } else {
                result.notImplemented();
            }
        }
        else if (call.method.equals("configureCrispSession")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;
            if (args != null) {
                CrispConfig config = CrispConfig.fromJson(args);

                // Configure Crisp session silently
                if (config.tokenId != null) {
                    Crisp.configure(context, config.websiteId, config.tokenId);
                } else {
                    Crisp.configure(context, config.websiteId);
                }

                Crisp.enableNotifications(context, config.enableNotifications);
                setCrispData(context, config);

                // Apply locale if provided
                if (config.local != null && !config.local.isEmpty()) {
                    try {
                        Locale locale = new Locale(config.local);
                        Locale.setDefault(locale);
                        android.content.res.Configuration configuration = context.getResources().getConfiguration();
                        configuration.setLocale(locale);
                        context.getResources().updateConfiguration(configuration, context.getResources().getDisplayMetrics());
                        Log.d("CRISP_CHAT", "Locale applied silently: " + config.local);
                    } catch (Exception e) {
                        Log.e("CRISP_CHAT", "Failed to set locale: " + config.local, e);
                    }
                }

                result.success("Crisp configured without opening chat");
            } else {
                result.error("INVALID_ARGUMENTS", "Arguments must be provided", null);
            }
        }
        else if (call.method.equals("resetCrispChatSession")) {
            Crisp.resetChatSession(context);
            result.success(null);
        }
        else if (call.method.equals("setSessionString")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;
            if (args != null) {
                String key = (String) args.get("key");
                String value = (String) args.get("value");
                Crisp.setSessionString(key, value);
                result.success(null);
            } else {
                result.notImplemented();
            }
        }
        else if (call.method.equals("setSessionInt")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;
            if (args != null) {
                String key = (String) args.get("key");
                int value = (int) args.get("value");
                Crisp.setSessionInt(key, value);
                result.success(null);
            } else {
                result.notImplemented();
            }
        }
        else if (call.method.equals("getSessionIdentifier")) {
            String sessionId = Crisp.getSessionIdentifier(context);
            if (sessionId != null) {
                result.success(sessionId);
            } else {
                result.error("NO_SESSION", "No active session found", null);
            }
        }
        else if (call.method.equals("setSessionSegments")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;
            if (args != null) {
                List<String> segments = (List<String>) args.get("segments");
                boolean overwrite = (boolean) args.get("overwrite");
                Crisp.setSessionSegments(segments, overwrite);
                result.success(null);
            } else {
                result.notImplemented();
            }
        }
        else if (call.method.equals("pushSessionEvent")) {
            HashMap<String, Object> args = (HashMap<String, Object>) call.arguments;

            if (args != null) {
                String name = (String) args.get("name");
                if (name == null || name.isEmpty()) {
                    result.error("INVALID_ARGUMENTS", "Missing 'name' argument", null);
                    return;
                }

                String colorString = (String) args.get("color");
                Color eventColor = parseColorOrDefault(colorString, Color.BLUE);

                im.crisp.client.external.data.SessionEvent event =
                        new im.crisp.client.external.data.SessionEvent(name, eventColor);

                Crisp.pushSessionEvent(event);
                result.success(null);
            } else {
                result.error("INVALID_ARGUMENTS", "Arguments must be a map", null);
            }
        }
        else {
            result.notImplemented();
        }
    }

    private void setCrispData(Context context, CrispConfig config) {
        if (config.tokenId != null) {
            Crisp.setTokenID(context, config.tokenId);
        }
        if (config.sessionSegment != null) {
            Crisp.setSessionSegment(config.sessionSegment);
        }
        if (config.user != null) {
            if (config.user.nickName != null) {
                Crisp.setUserNickname(config.user.nickName);
            }
            if (config.user.email != null) {
                boolean result = Crisp.setUserEmail(config.user.email);
                if (!result) {
                    Log.d("CRISP_CHAT", "Email not set");
                }
            }
            if (config.user.avatar != null) {
                boolean result = Crisp.setUserAvatar(config.user.avatar);
                if (!result) {
                    Log.d("CRISP_CHAT", "Avatar not set");
                }
            }
            if (config.user.phone != null) {
                boolean result = Crisp.setUserPhone(config.user.phone);
                if (!result) {
                    Log.d("CRISP_CHAT", "Phone not set");
                }
            }
            if (config.user.company != null) {
                Crisp.setUserCompany(config.user.company.toCrispCompany());
            }
        }
    }

    private void openActivity() {
        Intent intent = new Intent(context, ChatActivity.class);
        if (activity != null) {
            activity.startActivity(intent);
        } else {
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }

    private Color parseColorOrDefault(String colorString, Color defaultColor) {
        if (colorString == null) {
            return defaultColor;
        }

        String safeColor = colorString.toLowerCase(Locale.ROOT);

        switch (safeColor) {
            case "black": return Color.BLACK;
            case "blue": return Color.BLUE;
            case "brown": return Color.BROWN;
            case "green": return Color.GREEN;
            case "grey":
            case "gray": return Color.GREY;
            case "orange": return Color.ORANGE;
            case "pink": return Color.PINK;
            case "purple": return Color.PURPLE;
            case "red": return Color.RED;
            case "yellow": return Color.YELLOW;
            default:
                Log.w("CrispSDK", "Unknown color: " + safeColor + ". Using default color.");
                return defaultColor;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        context = null;
    }
}
