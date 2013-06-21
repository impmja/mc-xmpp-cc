//
//  MenuViewController.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "XMPPConnection.h"

@interface LoginViewController : UIViewController <XMPPConnectionDelegate>

@property (weak, nonatomic) IBOutlet UITextField *serverAddress;
@property (weak, nonatomic) IBOutlet UITextField *serverPort;
@property (weak, nonatomic) IBOutlet UITextField *jabberID;
@property (weak, nonatomic) IBOutlet UITextField *password;

- (IBAction)onConnectClick:(id)sender;

@end
