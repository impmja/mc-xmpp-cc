//
//  AppDelegate.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ECSlidingViewController.h"

#import "LoginViewController.h"
#import "ChatViewController.h"
#import "FriendsViewController.h"

#import "XMPPConnection.h"


//
//  AppDelegate
//
//  Note: Main entry point of the APP. Does keep track of all views there are and also of the XMPPConnection
//          as we need access to it in most views / controllers.
//
@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow                      *window;
@property (strong, nonatomic) UINavigationController        *rootNavigationController;
@property (strong, nonatomic) ECSlidingViewController       *slidingViewController;
@property (strong, nonatomic) LoginViewController           *loginViewController;
@property (strong, nonatomic) ChatViewController            *chatViewController;
@property (strong, nonatomic) FriendsViewController         *friendsViewController;

@property (strong, nonatomic) XMPPConnection                *xmppConnection;


#pragma mark - App Delegate Helper
+ (AppDelegate*) sharedAppDelegate;

@end
