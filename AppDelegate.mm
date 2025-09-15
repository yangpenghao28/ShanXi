//
//  AppDelegate.m
//  CamView Plus
//
//  Created by lovingc2009 on 2017/12/26.
//  Copyright © 2017年 lovingc2009. All rights reserved.
//


#import "AppDelegate.h"
#define ISCLEARARR @"isClearArr"
#define ISCLEARARR @"isClearArr12312312312"

//#import <objc/runtime.h>
//@interface NSArray(AA) {
//
//}
//+(void)load;
//-(id)customObjectAtIndex:(NSUInteger)idx;
//@end
//
//@implementation NSArray (AA)
//+(void)load {
//    Class cls = self;
//    SEL originalSelector = @selector(objectAtIndexedSubscript:);
//    SEL swizzledSelector = @selector(customObjectAtIndex:);
//    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
//    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
//    method_exchangeImplementations(originalMethod, swizzledMethod);
//}
//-(id)customObjectAtIndex:(NSUInteger)idx {
//    if (idx == 8) {
//        NSLog(@"12242525fafafaf");
//    }
//    return [self customObjectAtIndex:idx];
//}
//@end

@interface AppDelegate (){
    BOOL isTutkP2PDev;
    NSDictionary *_userInfo;
    UIBackgroundTaskIdentifier _backIden;
    NSTimer      *_logoutTimer;
    NSTimer      *_releaseP2PTimer;
    BOOL         _bP2PInited;
    NSUInteger   _backgroundRunTime; //seconds. App run time when in the background.
    BOOL         _isColdStart;
    BOOL         _noAddShareGroup;
    NSInteger    _actorPushIndex;
    RSNotification *_selectNoti;
}

@interface AppDelegate1 (){
    BOOL isTutkP2PDev;
    NSDictionary *_userInfo;
    UIBackgroundTaskIdentifier _backIden;
    NSTimer      *_logoutTimer;
    NSTimer      *_releaseP2PTimer;
    BOOL         _bP2PInited;
    NSUInteger   _backgroundRunTime; //seconds. App run time when in the background.
    BOOL         _isColdStart;
    BOOL         _noAddShareGroup;
    NSInteger    _actorPushIndex;
    RSNotification *_selectNoti;
}


@end

@implementation AppDelegate

- (void)loadMainWindow:(NSDictionary *)launchOptions{
    
    _backgroundRunTime = 30;
    NSLog(@"_backgroundRunTime:%lu",(unsigned long)_backgroundRunTime);

    //GoogleCast
    [self initializeChromCast];
    [self initializeDropBox];
#ifdef IS_DEFAULT_SYNPLAYBACK
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"RSSynPlayback"];
    if (!obj) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RSSynPlayback"];
    }
#endif

    [RSAmazonCastManager sharedInstance]; // ylytest
    
    RSLocalStorageManager *manager = [RSLocalStorageManager storageManager];
    if (manager.protectEnable) {
        RSPasswordSetViewController *vc = [[RSPasswordSetViewController alloc] initWithVerifyPasswordSuccess:^(RSPasswordSetViewController *verifyVC) {
            [verifyVC dismissViewControllerAnimated:YES completion:nil];
            self.window.rootViewController = [RSLiveNavigationController navigationController];
            if(launchOptions){
                NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
                //RSNotification *noti = [[RSNotification alloc] initWithUserInfo:userInfo];
                RSNotification *noti = [RSNotification notificationWithUserInfo:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
                [[RSNotificationManager sharedInstance] addNotification:noti];
                [RSMediator showNotification:noti];
            }
        }];
        vc.type = RSPasswordSetVCType_VerifyPassword_CannotBack;
        self.window.rootViewController = vc;
    }else{
        self.window.rootViewController = [RSLiveNavigationController navigationController];
    }
    [self.window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // Override point for customization after application launch.
    NSDictionary *dic = @{@"region" : @"region_us"};
    const char *param = [[RSDefineFuns convertToJsonData:dic] UTF8String];
    rs_sdk_wrapper_init(param);
    
    NSError *error;
    [NSFileManager.defaultManager removeItemAtPath:[NSString stringWithFormat:@"%@/Library/SplashBoard",NSHomeDirectory()] error:&error];
    if (error) {
        NSLog(@"Failed to delete launch screen cache: %@",error);
    }
    [RSDataMigration RXCamViewToCamViewPlus];
    [self initLogPath];
    RSLogToAll(@"============================================================");
    RSLogToAll(@"=================FinishLaunchingWithOptions=================");
    RSLogToAll(@"============================================================");
    
    [RSThirdPartService new];
    
    self.window = [[UIWindow alloc] init];
#ifndef   HideView
    if ([RSThirdPartService checkPrivacy]) {
        ///*/*[DataPersistenceUserDefaults checkAbideAgreement]==NO //0*/) {
        UIImage *image;
        
#ifdef APP_CHECK_PRIVACY
        RSPrivacyViewController *submit = [[RSPrivacyViewController alloc] init];
        submit.mode = 0;
        __weak typeof(self) w = self;
        submit.block = ^{
            __strong typeof(w) s = w;
            [s loadMainWindow:launchOptions];
        };
        
        UIColor *startColor = RSColor.theme.start;
        UIColor *endColor = RSColor.theme.end;
        image = [UIImage rs_imageWithStartColor:startColor endColor:endColor];
#else
        RSSubmitAgreementController *submit = [[RSSubmitAgreementController alloc] init];
        [submit.viewModel.submitSignal subscribeNext:^(id  _Nullable x) {
            [self loadMainWindow:launchOptions];
        }];
#endif
        UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:submit];
        navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
        
        if(image) {
            RS_ADAPT_NAVIGATION_BAR(navigationController.navigationBar, image);
        }
        
        [self.window setRootViewController:navigationController];
        [self.window makeKeyAndVisible];
    }else{
        [self loadMainWindow:launchOptions];
    }
#else
    HiviewHDViewController *adVC = [[HiviewHDViewController alloc] initWithNibName:@"HiviewHDViewController" bundle:nil];
    self.window.rootViewController = adVC;
    [self.window makeKeyAndVisible];
    __weak typeof(self) a = self;
    self.HVblock =  ^(){
        __strong typeof(a) b = a;
        [b loadMainWindow:launchOptions];
    };
#endif
    [RSDeviceManager sharedInstance];
#ifdef APP_TARGET_iUVSpro
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
#else
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
    
    //    self.window.rootViewController = [RSLiveNavigationController navigationController];
    //    [self.window makeKeyAndVisible];
    //    RSLocalStorageManager *manager = [RSLocalStorageManager storageManager];
    //    if (manager.protectEnable) {
    //        RSPasswordSetViewController *vc = [[RSPasswordSetViewController alloc] initWithVerifyPasswordSuccess:^(RSPasswordSetViewController *verifyVC) {
    //            [verifyVC dismissViewControllerAnimated:YES completion:nil];
    //        }];
    //        vc.type = RSPasswordSetVCType_VerifyPassword_CannotBack;
    //        [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
    //    }
    //    [RSDeviceManager sharedInstance];
    //    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Push
    [[RSNotificationManager sharedInstance] registerBPushWithApplication:application options:launchOptions];
    [application registerForRemoteNotifications];
    // Bugly ----specograyView 取消
//    if ([RSThirdPartService openUserPlan]) {
//        //        NSLog(@"开启bugly");
//        [[RSBugly sharedInstance] authorize];
//    }
    
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault , uuidRef);
    //    NSString *ocStrRef = (__bridge_transfer NSString*)strRef;
    //    NSString *uuidString = [ocStrRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *uuidString = [(__bridge NSString*)strRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *uuid=[RSUUIDManage readUUID];
    if (uuid == nil) {
        [RSUUIDManage deleteUUID];
        [RSUUIDManage saveUUID:uuidString];
    }
    NSLog(@"Mobile-UUID:%@",uuid);
    
#ifdef APP_TARGET_ISIWIPLUS
    [NSThread sleepForTimeInterval:3.0];
#endif
    self.model = [[RSNotificationExtensionModel alloc] init];
    _isColdStart = YES;
    _noAddShareGroup = NO;
    _selectNoti = [[RSNotification alloc] init];
    return YES;
}

#pragma mark App委托(全局方法)
+ (AppDelegate *)application
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)initLogPath {
    NSString *path = [NSString stringWithFormat:@"%@/Documents/RSLogs",NSHomeDirectory()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ) {//如果文件夹不存在
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDictionary *dic = @{
                          @"directory"       :path,
                          @"max size"        :@(2*1024*1024),
                          @"enable p2p log"  :@(true),
                          };
    
    NSString *param = [RSDefineFuns convertToJsonData:dic];

    char reverse[256] = {};
    init_log_ex_param paramEX = {param.UTF8String, logCallback, reverse[256]};
    rs_init_log_ex(&paramEX);
}

void logCallback(const char* message, void* reserve){
    printf("日志回调消息 = %s", message);
    NSString *msg = [NSString stringWithUTF8String:message];
    msg = [msg substringToIndex:(msg.length - 1) >= 0 ? (msg.length - 1) : msg.length];
    RSLogToAll(@"日志回调消息 = %@", msg);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    RSLogToAll(@"WillResignActive");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    RSLogToAll(@"=================EnterBackground=================");
    [self beginTask];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    RSLogToAll(@"=================BecomeActive=================");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    RSLogToAll(@"内网IP: %@",[RSIPAddress getIPAddress:YES]);
    [self endTask];
    [self loginAllDevices];
    if (_isColdStart) {
        _isColdStart = !_isColdStart;
        [self getDataWithShereGroup];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
 
    //release p2p
    rs_sdk_wrapper_uninit(NULL);
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    _isColdStart = YES; //此处应该是热启动AP，为了适配扩展RS启动后要读取ShareGroup数据，设置为YES
    RSLogToAll(@"=================EnterForeground=================");
}


#pragma mark - UpDateShareGroupData
- (void)getDataWithShereGroup{
    RSDeviceManager *deviceMana = [RSDeviceManager sharedInstance];
    NSArray *deviceArr = deviceMana.deviceList;
    NSString *groupPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:RS_GROUP_ID] path];
    NSMutableArray *infoArr = [NSMutableArray array];
    if (deviceArr != nil) {
        for (RSDeviceObj *dev in deviceArr) {
//              存在隐藏文件.com.apple.mobile_container_manager.metadata.plist,Library
            if (dev.pushType == RSPUSHTYPE_AL) {
                NSMutableArray<NSDictionary *> *pushData = [self.model getPushDataWithPushID:dev.pushID];
                if (pushData.count != 0) {
                    NSString *documentPath = [NSString stringWithFormat:@"%@/%@", groupPath,dev.pushID];
                    [pushData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSData *pushData = [NSData dataWithContentsOfFile:[documentPath stringByAppendingFormat:@"/%@",obj]];
                        NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:pushData options:NSJSONReadingMutableContainers error:nil];
                        if (userInfo != nil) {
                            RSNotification *noti = [RSNotification notificationWithUserInfo:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
                            [[RSNotificationManager sharedInstance] addNotification:noti];
                            [infoArr addObject:noti];
                        }else{
                            return;
                        }
                    }];
                    if ([dev.pushID isEqualToString:_selectNoti.pushID] && _noAddShareGroup){
                        _noAddShareGroup = !_noAddShareGroup;
                        RSNotification *noti = [infoArr objectAtIndex:_actorPushIndex];
                        [RSMediator showNotification:noti];
                    }
                    [[RSNotificationExtensionModel sharedInstance] removeAllPushDataWithPushID:dev.pushID];
                }
            }
        }
    }
}

#pragma mark - Notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[RSNotificationManager sharedInstance] rigisterDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"远程通知注册失败信息---%@",error);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) {
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"iOS10 前台收到远程通知:%@",userInfo);
//    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
//    content.sound = [UNNotificationSound soundNamed:@"test1.caf"];
//    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
//       NSLog(@"iOS10 前台收到远程通知:%@",userInfo);
//
//    }
//    else {
//        // 判断为本地通知
//        NSLog(@"iOS10 前台收到本地通知:%@",userInfo);
//    }
//    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
    RSNotification *noti = [RSNotification notificationWithUserInfo:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
    [[RSNotificationManager sharedInstance] addNotification:noti];
    NSArray *arry = userInfo.allKeys;
    if ([arry[1] isEqualToString:@"msg"]) { //特殊字段区分是否是RS推送
        //删除共享目录中对应的数据
        NSDictionary *notiDic = [self getParamWithServerNoti:userInfo];
        [[RSNotificationExtensionModel sharedInstance] removeOncePushDataWithPushID:notiDic[@"PushID"] pushDate:notiDic[@"Time"] pushType:notiDic[@"Type"] channel:notiDic[@"Channel"] isHostAP:YES];
    }
}

- (NSDictionary *)getParamWithServerNoti:(NSDictionary *)userInfo {
    id info = userInfo[@"msg"];
    NSData *data = [info dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    return dic;
}


- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __TVOS_PROHIBITED {
    NSLog(@"后台点击或退出程序调用");
    RSLogToAll(@"Notification Click in Notification Center")
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    __block RSNotification *noti = [RSNotification notificationWithUserInfo:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
    NSArray *arry = userInfo.allKeys;
    if ([arry[1] isEqualToString:@"msg"]) { //特殊字段区分是否是RS推送
        NSMutableArray *listArr = [RSNotificationManager sharedInstance].notificationList;
        NSDictionary *notiDic = [self getParamWithServerNoti:userInfo];
        __block BOOL isExists = NO;
        __block BOOL isDelete = YES;
        //查看push列表中是否包含点击的通知
        [listArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RSNotification *notifi = obj;
            if (([notifi.alarmTime isEqualToString:notiDic[@"Time"]]) && ([notifi.pushID isEqualToString:notiDic[@"PushID"]]) && ([notifi.message[@"Type"] isEqualToString:notiDic[@"Type"]]) && ([notifi.message[@"Channel"] integerValue] == [notiDic[@"Channel"] integerValue])) {
                isExists = YES;
                noti = notifi;
            }
        }];
        //查看现存的共享组中是否包含点击的推送-------如果列表中没有，现存的共享组中也没有 ->此推送是原来的推送并且列表中被清除了 isDelete = YES;
        if ([[RSNotificationExtensionModel sharedInstance] getPushDataWithPushID:notiDic[@"PushID"]].count != 0) {
            [[RSNotificationExtensionModel sharedInstance].pushExtenArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *resultDic = [[RSNotificationExtensionModel sharedInstance] getPushInfoWithPushID:notiDic[@"PushID"] pushDate:obj];
                if (([resultDic[@"Time"] isEqualToString:notiDic[@"Time"]]) && ([resultDic[@"PushID"] isEqualToString:notiDic[@"PushID"]]) && ([resultDic[@"Type"] isEqualToString:notiDic[@"Type"]]) && ([resultDic[@"Channel"] integerValue] == [notiDic[@"Channel"] integerValue])) {
                    isDelete = NO;
                }
            }];
        }
        if (!isExists) { //数据库中没有,目前还存在于共享组中
            if (isDelete) {//共享组和数据库中都没有-（1.已经将所有的推送加入至数据库，但是又被在AP中清除了数据库2.数量超过最大数量）
                [RSMediator showNotification:noti];
                return;
            }else{//共享组中包含
                _noAddShareGroup = YES;
                //记录此次点击再共享组中的位置(共享组中是已排过序的)，后面会加入剩余还在共享组中的数据
                _actorPushIndex = [self.model getPushOfIndexWithShareGroup:notiDic[@"PushID"] actorPushInfo:userInfo];
                _selectNoti = noti;
            }
        }else{ //数据库有
            [RSMediator showNotification:noti];
        }
    }else{
        [[RSNotificationManager sharedInstance] addNotification:noti];
        [RSMediator showNotification:noti];
    }
}

//iOS7后支持多任务，可以再后台做一些事情，此方法的调用有效负载中必须包含content-available = 1，然后无论前台或后台都会调用，静默推送基于UIBackgroundFetchResult模式来触发此方法
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    RSNotification *noti = [RSNotification notificationWithUserInfo:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
    NSLog(@"静默推送");
    [[RSNotificationManager sharedInstance] addNotification:noti];
    //在前台不跳转到回放, 从后台点击跳转到回放
    if (application.applicationState != UIApplicationStateActive) {
        RSLogToAll(@"Notification Click in Notification Center")
        [RSMediator showNotification:noti];
    }
}

//此方法ios7后弃用了
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSString *uid = notification.userInfo[@"uid"];
    RSNotification *noti = [[RSNotificationManager sharedInstance] notificationWithUid:uid];
    
    //在前台不跳转到回放, 从后台点击跳转到回放
    if (application.applicationState != UIApplicationStateActive) {
        if (noti) {
            [RSMediator showNotification:noti];
        }
    }
}

#pragma mark - Dropbox
/// 初始化DropBox
- (void)initializeDropBox{
    [DBClientsManager setupWithAppKey:DropBoxAppKey];
}

/// DropBox认证回调
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    
    [DBClientsManager handleRedirectURL:url completion:^(DBOAuthResult * _Nullable authResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (authResult != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RS_Notification_DropBox_Return object:authResult];
            }
        });
    }];
    return NO;
}

//进入后台
- (void)beginTask
{
    _backIden = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"dajun task over");
        [self logoutAllDevices];
        [self endTask];
    }];
    [self startLogoutTimer];
    [self startReleaseP2PTimer];
}

- (void)endTask
{
    if(_backIden != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backIden];
        _backIden = UIBackgroundTaskInvalid;
        NSLog(@"dajun end task.");
    }
    [self stopLogoutTimer];
    [self stopReleaseP2PTimer];
}

- (void)releaseP2P{
    rs_destroy_p2p_resource_enter_background();
}

- (void)logoutAllDevices{
    [[RSDeviceManager sharedInstance].deviceList makeObjectsPerformSelector:@selector(Logout)];
}

- (void)loginAllDevices{
    [[RSDeviceManager sharedInstance] enableTutkManyConnectionIfNeeded];
    [[RSDeviceManager sharedInstance].deviceList makeObjectsPerformSelector:@selector(Login)];
}

- (void)stop:(NSTimer *)timer{
    if(timer == _logoutTimer) {
        [self logoutAllDevices];
        [self stopLogoutTimer];
    }
    
    if(timer == _releaseP2PTimer) {
        [self releaseP2P];
        [self stopReleaseP2PTimer];
    }
}

- (void)startLogoutTimer{
    if(_logoutTimer) {
        [self stopLogoutTimer];
    }
    _logoutTimer = [NSTimer scheduledTimerWithTimeInterval:_backgroundRunTime/3 target:self selector:@selector(stop:) userInfo:nil repeats:NO];
}
-(void)stopLogoutTimer
{
    if(_logoutTimer) {
        [_logoutTimer invalidate];
        _logoutTimer = nil;
    }
}

- (void)startReleaseP2PTimer{
    if(_releaseP2PTimer){
        [self stopReleaseP2PTimer];
    }
    _releaseP2PTimer = [NSTimer scheduledTimerWithTimeInterval:_backgroundRunTime*2/3 target:self selector:@selector(stop:) userInfo:nil repeats:NO];
}

- (void)stopReleaseP2PTimer{
    if(_releaseP2PTimer){
        [_releaseP2PTimer invalidate];
        _releaseP2PTimer = nil;
    }
}

#pragma mark - ChromeCast
/// 初始化ChromeCast
- (void)initializeChromCast{
    GCKDiscoveryCriteria *criteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:kGCKDefaultMediaReceiverApplicationID];

    //    GCKDiscoveryCriteria *criteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:@"3C5F6683"];
    GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
    [GCKCastContext setSharedInstanceWithOptions:options];
    
    [[GCKCastContext sharedInstance].sessionManager addListener:self];
    [GCKCastContext sharedInstance].imagePicker = self;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didEndSession:(GCKSession *)session withError:(NSError *)error {
    if (!error) {
        
    } else {
        NSString *message = [NSString stringWithFormat:@"Session ended unexpectedly:\n%@", error.localizedDescription];
        [self showAlertWithTitle:@"Session error" message:message];
    }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"Failed to start session:\n%@", error.localizedDescription];
    [self showAlertWithTitle:@"Session error" message:message];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (GCKImage *)getImageWithHints:(GCKUIImageHints *)imageHints fromMetadata:(GCKMediaMetadata *)metadata {
    if (metadata && metadata.images && ((metadata.images).count > 0)) {
        if ((metadata.images).count == 1) {
            return (metadata.images)[0];
        } else {
            if (imageHints.imageType == GCKMediaMetadataImageTypeBackground) {
                return (metadata.images)[1];
            } else {
                return (metadata.images)[0];
            }
        }
    } else {
        NSLog(@"No images available in media metadata. ");
        return nil;
    }
}

#pragma mark - HDVision 广告图禁止横屏
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (_allowRotation == 1) {
        return UIInterfaceOrientationMaskPortrait;//只有当时HivierHD的时候才只会竖屏
        
    }else {
        return UIInterfaceOrientationMaskAllButUpsideDown;//其他情况支持横竖屏
        
    }
    
}

-(void)testYang {
    NSLog(@"TestYang");
}

@end
