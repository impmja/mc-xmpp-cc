//
//  AppDelegate.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

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
    
    // create sliding view controller
    _slidingViewController = [[ECSlidingViewController alloc] init];
    _slidingViewController.anchorLeftRevealAmount = 280.0f;
    _slidingViewController.anchorRightRevealAmount = 280.0f;
    // setup sliding view
    _slidingViewController.topViewController = _chatViewController;
    
    [_rootNavigationController pushViewController:_slidingViewController animated:NO];
    [_rootNavigationController.view addGestureRecognizer:_slidingViewController.panGesture];
    
    // check if the user has logged in the last session, if so, auto reconnect him to the last used server
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * serverAddress = [defaults objectForKey:@"serverAddress"];
    NSNumber * serverPort = [defaults objectForKey:@"serverPort"];
    NSString * jabberID = [defaults objectForKey:@"jabberID"];
    NSString * password = [defaults objectForKey:@"password"];
    
    // try to establish a connection
    if (serverAddress != nil && serverAddress.length > 0 &&
        serverPort != nil &&
        jabberID != nil && jabberID.length > 0 &&
        password != nil && password.length > 0) {
        
        self.xmppConnection = [[XMPPConnection alloc] initWithHost:serverAddress andPort:[serverPort intValue]];
        [self.xmppConnection connectWithJID:jabberID andPassword:password];
    }
 
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - App Delegate Helper
+ (AppDelegate*) sharedAppDelegate {
	return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}


@end
