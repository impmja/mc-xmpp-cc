//
//  MenuViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import "LoginViewController.h"
#include "ECSlidingViewController.h"
#include "AppDelegate.h"


@interface LoginViewController ()

@end


@implementation LoginViewController

#pragma mark Accessors
- (AppDelegate*)appDelegate {
	return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.slidingViewController.anchorLeftRevealAmount = 320.0f;
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    [self.password setSecureTextEntry:YES];
    [self.password setAutocorrectionType:UITextAutocorrectionTypeNo];
}

- (void)viewWillAppear:(BOOL)animated {
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    self.slidingViewController.anchorLeftRevealAmount = 320.0f;
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
}



- (IBAction)onConnectClick:(id)sender {
    
    NSString * serverAddress = self.serverAddress.text;
    NSNumber * serverPort = [NSNumber numberWithInt:[self.serverPort.text intValue]];
    NSString * jabberID = self.jabberID.text;
    NSString * password = self.password.text;

    // try to establish connection
    if (serverAddress != nil && serverAddress.length > 0 &&
        serverPort != nil &&
        jabberID != nil && jabberID.length > 0 &&
        password != nil && password.length > 0) {
        
        XMPPConnection * con = [[XMPPConnection alloc] initWithHost:serverAddress andPort:[serverPort intValue]];
        if ([con connectWithJID:jabberID andPassword:password] ==  YES) {
            // TODO
            
            
        } else {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot establish connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length > 0) {
        [self.view hideKeyboard];
        [textField resignFirstResponder];
        return YES;
    }
    return NO;
}


@end
