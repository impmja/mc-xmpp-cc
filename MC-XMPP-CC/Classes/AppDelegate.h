//
//  AppDelegate.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ECSlidingViewController.h"

#import "MenuViewController.h"
#import "ChatViewController.h"
#import "FriendsViewController.h"

#import "XMPPConnection.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow                      *window;
@property (strong, nonatomic) UINavigationController        *rootNavigationController;
@property (strong, nonatomic) ECSlidingViewController       *slidingViewController;
@property (strong, nonatomic) MenuViewController            *menuViewController;
@property (strong, nonatomic) ChatViewController            *chatViewController;
@property (strong, nonatomic) FriendsViewController         *friendsViewController;



@end
