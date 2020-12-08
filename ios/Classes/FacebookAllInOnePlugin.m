#import "FacebookAllInOnePlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FacebookAllInOnePlugin()<FlutterStreamHandler>
@property(nonatomic,copy)FlutterResult pendingResult;
@property(nonatomic,strong)FBSDKLoginManager *loginManager;
@property(nonatomic,copy)NSString *launchingLink;
@property(nonatomic,copy)NSString *latestLink;
@property(nonatomic,strong)FlutterEventSink eventSink;
@end

@implementation FacebookAllInOnePlugin


- (instancetype)init
{
    self = [super init];
    if (self) {
        [FBSDKApplicationDelegate initializeSDK:nil];
        self.loginManager = [[FBSDKLoginManager alloc]init];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"VistaTeam/facebook_all_in_one"
                                     binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel *chargingChannel =
          [FlutterEventChannel eventChannelWithName:@"VistaTeam/facebook_all_in_one_events"
                                    binaryMessenger:[registrar messenger]];
    
    
    FacebookAllInOnePlugin* instance = [[FacebookAllInOnePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [chargingChannel setStreamHandler:instance];
    [registrar addApplicationDelegate:instance];
}

- (void)setLatestLink:(NSString *)latestLink {
    static NSString *key = @"latestLink";

    [self willChangeValueForKey:key];
    _latestLink = [latestLink copy];
    [self didChangeValueForKey:key];

    if (self.eventSink){
        self.eventSink(self.latestLink);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL *url = (NSURL *)launchOptions[UIApplicationLaunchOptionsURLKey];
    if (url) {
        self.launchingLink = [url absoluteString];
    }
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url options:options];
    self.latestLink = [url absoluteString];
    return YES;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if ([@"getLaunchingLink" isEqualToString:call.method]){
        // get Launching Link
        [self getLaunchingLinkWithMethodCall:call result:result];
    }else if ([@"getFBLinks" isEqualToString:call.method]){
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
        [self handleFacebookEventMethodCall:call result:result];
        
    }
}

- (void)handleFacebookEventMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"clearUserData" isEqualToString:call.method]) {
        //clearUserData
        [self fbEventClearUserDataWithMethodCall:call result:result];
    } else if ([@"clearUserID" isEqualToString:call.method]){
        // clearUserID
        [self fbEventClearUserIDWithMethodCall:call result:result];
    } else if ([@"flush" isEqualToString:call.method]){
        // flush
        [self fbEventFlushWithMethodCall:call result:result];
    } else if ([@"getApplicationId" isEqualToString:call.method]){
        // getApplicationId
        [self fbEventGetApplicationIdWithMethodCall:call result:result];
    } else if ([@"logEvent" isEqualToString:call.method]){
        // logEvent
        [self fbEventLogEventWithMethodCall:call result:result];
    } else if ([@"logPushNotificationOpen" isEqualToString:call.method]){
        // logPushNotificationOpen
        [self fbEventPushNotificationOpenWithMethodCall:call result:result];
    } else if ([@"setUserData" isEqualToString:call.method]){
        // setUserData
        [self fbEventSetUserDataWithMethodCall:call result:result];
    } else if ([@"setUserID" isEqualToString:call.method]){
        // setUserID
        [self fbEventSetUserIDWithMethodCall:call result:result];
    } else if ([@"updateUserProperties" isEqualToString:call.method]){
        // updateUserProperties
        [self fbEventUpdateUserPropertiesWithMethodCall:call result:result];
    } else if ([@"setAutoLogAppEventsEnabled" isEqualToString:call.method]){
        // setAutoLogAppEventsEnabled
        [self fbEventSetAutoLogAppEventsEnabledWithMethodCall:call result:result];
    } else if ([@"setDataProcessingOptions" isEqualToString:call.method]){
        // setDataProcessingOptions
        [self fbEventsetDataProcessingOptionsWithMethodCall:call result:result];
    } else if ([@"logPurchase" isEqualToString:call.method]){
        // logPurchase
        [self fbEventPurchasedWithMethodCall:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}


/// getLaunchingLink
/// @param call FlutterMethodCall
/// @param result Result To Flutter CallBack
- (void)getLaunchingLinkWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(self.launchingLink);
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
             [self finishWithError:@"error make sure that your  Info.plist is configured"];
        }else {
           NSMutableDictionary *resultData = [[NSMutableDictionary alloc]init];
            if (fbResult.isCancelled) {
                resultData[@"status"] = @403;
            }else {
                resultData[@"status"] = @200;
                resultData[@"accessToken"] = [self getAccessToken:fbResult.token];
                resultData[@"grantedPermissions"] = [fbResult.grantedPermissions allObjects];
                resultData[@"declinedPermissions"] = [fbResult.declinedPermissions allObjects];
            }
            [self finishWithResult:resultData];
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
    atDict[@"expires"] = [[NSNumber alloc]initWithInteger:(NSInteger)(accessToken.expirationDate.timeIntervalSince1970 * 1000)];
    atDict[@"grantedPermissions"] = [accessToken.permissions.allObjects mutableCopy];;
    atDict[@"declinedPermissions"] = [accessToken.declinedPermissions.allObjects mutableCopy];;
    return atDict;
}


#pragma mark -  facebook event
// ClearUserData
-(void)fbEventClearUserDataWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    [FBSDKAppEvents clearUserData];
    flutterResult(nil);
}

// Clear UserID
-(void)fbEventClearUserIDWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    [FBSDKAppEvents clearUserID];
    flutterResult(nil);
}

// Flush
-(void)fbEventFlushWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    [FBSDKAppEvents flush];
    flutterResult(nil);
}

// GetApplicationId
-(void)fbEventGetApplicationIdWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    flutterResult(FBSDKSettings.appID);
}

// LogEvent
-(void)fbEventLogEventWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSString *eventName = call.arguments[@"name"];
    NSDictionary *parameters = call.arguments[@"parameters"];
    NSNumber *valueToSumNumber = call.arguments[@"_valueToSum"];
    if (valueToSumNumber != nil) {
        [FBSDKAppEvents logEvent:eventName valueToSum:valueToSumNumber.doubleValue parameters:parameters];
    }else {
        [FBSDKAppEvents logEvent:eventName parameters:parameters];
    }
    flutterResult(nil);
}

// PushNotificationOpen
-(void)fbEventPushNotificationOpenWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSDictionary *parameters = call.arguments[@"payload"];
    NSString *action = call.arguments[@"action"];
    if (action != nil){
        [FBSDKAppEvents logPushNotificationOpen:parameters action:action];
    }else {
        [FBSDKAppEvents logPushNotificationOpen:parameters];
    }
    flutterResult(nil);
}

// SetUserData
-(void)fbEventSetUserDataWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSString *email = call.arguments[@"email"];
    if (email != nil)[FBSDKAppEvents setUserData:email forType:FBSDKAppEventEmail];
    
    NSString *firstName = call.arguments[@"firstName"];
    if (firstName != nil)[FBSDKAppEvents setUserData:firstName forType:FBSDKAppEventFirstName];
    
    NSString *lastName = call.arguments[@"lastName"];
    if (lastName != nil)[FBSDKAppEvents setUserData:lastName forType:FBSDKAppEventLastName];
    
    NSString *phone = call.arguments[@"phone"];
    if (phone != nil)[FBSDKAppEvents setUserData:phone forType:FBSDKAppEventPhone];
    
    NSString *dateOfBirth = call.arguments[@"dateOfBirth"];
    if (dateOfBirth != nil)[FBSDKAppEvents setUserData:dateOfBirth forType:FBSDKAppEventDateOfBirth];
    
    NSString *gender = call.arguments[@"gender"];
    if (gender != nil)[FBSDKAppEvents setUserData:gender forType:FBSDKAppEventGender];
    
    NSString *city = call.arguments[@"city"];
    if (city != nil)[FBSDKAppEvents setUserData:city forType:FBSDKAppEventCity];
    
    NSString *state = call.arguments[@"state"];
    if (state != nil)[FBSDKAppEvents setUserData:state forType:FBSDKAppEventState];
    
    NSString *zip = call.arguments[@"zip"];
    if (zip != nil)[FBSDKAppEvents setUserData:zip forType:FBSDKAppEventZip];
    
    NSString *country = call.arguments[@"country"];
    if (country != nil)[FBSDKAppEvents setUserData:country forType:FBSDKAppEventCountry];
    
    flutterResult(nil);
}

// SetUserID
-(void)fbEventSetUserIDWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    FBSDKAppEvents.userID = call.arguments;
    flutterResult(nil);
}

// UpdateUserProperties
-(void)fbEventUpdateUserPropertiesWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSDictionary *parameters = call.arguments[@"parameters"];
    
    [FBSDKAppEvents updateUserProperties:parameters handler:^(FBSDKGraphRequestConnection * _Nullable connection, id  _Nullable result, NSError * _Nullable error) {
            if (error != nil) {
                flutterResult(nil);
            }else {
                flutterResult(result);
            }
    }];
    
}

// SetAutoLogAppEventsEnabled
-(void)fbEventSetAutoLogAppEventsEnabledWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    bool enabled = call.arguments;
    [FBSDKSettings setAutoLogAppEventsEnabled:enabled];
    flutterResult(nil);
}

// setDataProcessingOptions
-(void)fbEventsetDataProcessingOptionsWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSArray *modes = call.arguments[@"options"];
    NSNumber *state = call.arguments[@"state"];
    NSNumber *country = call.arguments[@"country"];
    [FBSDKSettings setDataProcessingOptions:modes country:country.intValue state:state.intValue];
    flutterResult(nil);
}

// Purchased
-(void)fbEventPurchasedWithMethodCall:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSNumber *amount = call.arguments[@"amount"];
    NSString *currency = call.arguments[@"currency"];
    NSDictionary *parameters = call.arguments[@"parameters"];
    
    [FBSDKAppEvents logPurchase:amount.doubleValue currency:currency parameters:parameters];
    
    flutterResult(nil);
}

@end
