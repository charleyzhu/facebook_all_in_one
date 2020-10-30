#import "FacebookAllInOnePlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FacebookAllInOnePlugin()
@property(nonatomic,copy)FlutterResult pendingResult;
@property(nonatomic,strong)FBSDKLoginManager *loginManager;

@end

@implementation FacebookAllInOnePlugin

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.loginManager = [[FBSDKLoginManager alloc]init];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"VistaTeam/facebook_all_in_one"
                                     binaryMessenger:[registrar messenger]];
    
    
    [FBSDKApplicationDelegate initializeSDK:nil];
    
    FacebookAllInOnePlugin* instance = [[FacebookAllInOnePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
    
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url options:options];
    return YES;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"getFBLinks" isEqualToString:call.method]){
        // get deep links
        [self getFacebookLinskWithMethodCall:call result:result];
    }else if ([@"login" isEqualToString:call.method]){
        // facebook login
        [self facebookLoginWithMethodCall:call result:result];
    }else if ([@"isLogged" isEqualToString:call.method]){
        // isLogged
        [self isLoggedWithMethodCall:call result:result];
    }else if ([@"getUserData" isEqualToString:call.method]){
        // getUserData
        [self getUserDataWithMethodCall:call result:result];
    }else if ([@"logOut" isEqualToString:call.method]){
        // logOut
        [self logoutWithMethodCall:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}


/// getFacebook DeepLink
/// @param call FlutterMethodCall
/// @param result   Result To Flutter CallBack
- (void)getFacebookLinskWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Received error while fetching deferred app link %@",error);
            result([FlutterError errorWithCode:@"601" message:error.localizedDescription details:nil]);
        }
        
        if (url) {
            NSLog(@"FB APP LINKS getting url: %@", url.absoluteString);
            NSMutableDictionary *resultData = [[NSMutableDictionary alloc]init];
            resultData[@"deeplink"] = url.absoluteString;
            
            NSString *code = [FBSDKAppLinkUtility appInvitePromotionCodeFromURL:url];
            NSLog(@"promotional:%@",code);
            if (code) {
                resultData[@"promotionalCode"] = code;
            }else {
                resultData[@"promotionalCode"] = @"";
            }
            
            result(resultData);
        }else {
            result(nil);
        }
        
        
        
    }];
}

- (void)facebookLoginWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    BOOL isOk = [self setPendingResultWithMethodName:call.method FlutterResult:flutterResult];
    if (!isOk)return;
    
    NSArray *permissions = call.arguments[@"permissions"];
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [self.loginManager logInWithPermissions:permissions fromViewController:viewController handler:^(FBSDKLoginManagerLoginResult * _Nullable fbResult, NSError * _Nullable error) {
        if (error != nil) {
            NSMutableDictionary *resultData = [[NSMutableDictionary alloc]init];
            if (fbResult.isCancelled) {
                resultData[@"status"] = @403;
                [self finishWithResult:resultData];
            }else {
                resultData[@"status"] = @200;
                resultData[@"accessToken"] = [self getAccessToken:fbResult.token];
                resultData[@"grantedPermissions"] = fbResult.grantedPermissions;
                resultData[@"status"] = fbResult.declinedPermissions;
            }
        }else {
            [self finishWithError:@"error make sure that your  Info.plist is configured"];
        }
    }];
}


/// isLogged
/// @param call FlutterMethodCall
/// @param flutterResult FlutterResult
- (void)isLoggedWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    BOOL isOk = [self setPendingResultWithMethodName:call.method FlutterResult:flutterResult];
    if (!isOk)return;
    
    if (FBSDKAccessToken.isCurrentAccessTokenActive) {
        NSDictionary *tokenDict = [self getAccessToken:FBSDKAccessToken.currentAccessToken];
        [self finishWithResult:tokenDict];
    }else {
        [self finishWithResult:nil];
    }
}


/// getUserData
/// @param call FlutterMethodCall
/// @param flutterResult flutterResult
- (void)getUserDataWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    BOOL isOk = [self setPendingResultWithMethodName:call.method FlutterResult:flutterResult];
    if (!isOk)return;
    
    NSString *fields = call.arguments[@"fields"];
    
    
    FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields":fields}];
    [graphRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection * _Nullable connection, id  _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            [self finishWithError:@"error get user data from facebook Graph, please check your fileds and your permissions"];
        }else {
            [self finishWithResult:result];
        }
    }];
}


/// logout
/// @param call FlutterMethodCall
/// @param flutterResult flutterResult
- (void)logoutWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    BOOL isOk = [self setPendingResultWithMethodName:call.method FlutterResult:flutterResult];
    if (!isOk)return;
    [self.loginManager logOut];
    [self finishWithResult:nil];
}


- (BOOL)setPendingResultWithMethodName:(NSString *)methodName FlutterResult:(FlutterResult)flutterResult {
    if (self.pendingResult != nil) {
        flutterResult([FlutterError errorWithCode:@"500" message:[NSString stringWithFormat:@"%@ called while another Facebook login operation was in progress.",methodName] details:nil]);
        return NO;
    }
    self.pendingResult = flutterResult;
    return YES;
}

- (void)finishWithResult:(id)data {
    if (self.pendingResult != nil) {
        self.pendingResult(data);
        self.pendingResult = nil;
    }
    
}

- (void)finishWithError:(NSString *)message {
    if (self.pendingResult != nil) {
        self.pendingResult([FlutterError errorWithCode:@"500" message:message details:nil]);
        self.pendingResult = nil;
    }
}

-(NSDictionary *)getAccessToken:(FBSDKAccessToken *)accessToken {
    NSMutableDictionary *atDict = [[NSMutableDictionary alloc]init];
    atDict[@"token"] = accessToken.tokenString;
    atDict[@"userId"] = accessToken.userID;
    atDict[@"expires"] = [[NSNumber alloc]initWithDouble:accessToken.expirationDate.timeIntervalSince1970 * 1000];
    atDict[@"grantedPermissions"] = [accessToken.permissions.allObjects mutableCopy];;
    atDict[@"declinedPermissions"] = [accessToken.declinedPermissions.allObjects mutableCopy];;
    return atDict;
}
@end
