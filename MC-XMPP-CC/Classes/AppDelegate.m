//
//  AppDelegate.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import "AppDelegate.h"

#import "DDLog.h"
#import "DDTTYLogger.h"


@implementation AppDelegate

@synthesize rootNavigationController = _rootNavigationController;
@synthesize slidingViewController = _slideViewController;
@synthesize loginViewController = _loginViewController;
@synthesize chatViewController = _chatViewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Configure logging framework
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // create root navigation controller
    _rootNavigationController = [[UINavigationController alloc] initWithRootViewController:self.window.rootViewController];
    [_rootNavigationController setNavigationBarHidden:YES];
    self.window.rootViewController = _rootNavigationController;
    
    // create menu view controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    _loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    
    // create chat view controller
    _chatViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChatView"];
    
    // create friends view controller
    _friendsViewController = [storyboard instantiateViewControllerWithIdentifier:@"FriendsView"];
    
    // create slide controller
    _slideViewController = [[ECSlidingViewController alloc] init];
    _slideViewController.topViewController = _chatViewController;
    [_rootNavigationController pushViewController:_slideViewController animated:NO];
    
    [_rootNavigationController.view addGestureRecognizer:_slideViewController.panGesture];
    
    //[_slideViewController anchorTopViewTo:ECRight];
    
    
    /*
    // check if the user is has logged in
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * serverAddress = [defaults objectForKey:@"serverAddress"];
    NSNumber * serverPort = [defaults objectForKey:@"serverPort"];
    NSString * jabberID = [defaults objectForKey:@"jabberID"];
    NSString * password = [defaults objectForKey:@"password"];
    
    // try to establish connection
    if (serverAddress != nil && serverAddress.length > 0 &&
        serverPort != nil &&
        jabberID != nil && jabberID.length > 0 &&
        password != nil && password.length > 0) {
        
        self.xmppConnection = [[XMPPConnection alloc] initWithHost:serverAddress andPort:[serverPort intValue]];
        [self.xmppConnection connectWithJID:jabberID andPassword:password];
    }
    */
    
    self.xmppConnection = [[XMPPConnection alloc] initWithHost:@"katzensaft.burstdamage.de" andPort:5222];
    [self.xmppConnection connectWithJID:@"test1@xmppserver" andPassword:@"1234"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
