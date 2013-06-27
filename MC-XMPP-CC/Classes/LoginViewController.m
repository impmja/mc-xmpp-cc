//
//  MenuViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte and Florian Kaluschke on 16.04.13.
//  Copyright (c) 2013 Jan Schulte and Florian Kaluschke. All rights reserved.
//

#import "LoginViewController.h"
#include "ECSlidingViewController.h"

#include "AppDelegate.h"

@interface LoginViewController() {
    XMPPConnection  *newConnection;
}
@end


@implementation LoginViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    [self.password setSecureTextEntry:YES];
    [self.password setAutocorrectionType:UITextAutocorrectionTypeNo];
}

- (void)viewWillAppear:(BOOL)animated {

    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    self.serverAddress.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.serverAddress.enablesReturnKeyAutomatically = YES;
    
    // read connection info
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.serverAddress.text = [defaults objectForKey:@"serverAddress"];
    self.serverPort.text = [defaults objectForKey:@"serverPort"];
    self.jabberID.text = [defaults objectForKey:@"jabberID"];
    self.password.text = [defaults objectForKey:@"password"];
    
    self.status.lineBreakMode = NSLineBreakByWordWrapping;
    self.status.numberOfLines = 0;
    
    if ([AppDelegate sharedAppDelegate].xmppConnection != nil &&  [AppDelegate sharedAppDelegate].xmppConnection.isConnected) {
        [self showStatus:@"Connected."];
    } else {
         [self showStatus:@"Not connected."];
    }
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
        
        // try to create a new connection.
        // Note: Does NOT close the current one until there has being a successful connection established
        newConnection = [[XMPPConnection alloc] initWithHost:serverAddress andPort:[serverPort intValue]];
        newConnection.delegate = self;
        [newConnection connectWithJID:jabberID andPassword:password];
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

#pragma mark - XMPPConnection Callbacks
-(void)onXMPPConnectionFailed:(XMPPConnection *)sender withError:(NSError *)error {
    
    newConnection = nil;
    
    [self showStatus:error.localizedDescription];
    
    /*
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil, nil];
    [alert show];
    */
}

-(void)onXMPPConnectionSucceeded:(XMPPConnection *)sender {
    
    [self showStatus:@"Connection succeeded."];
    
    // store login data for auto login
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:self.serverAddress.text forKey:@"serverAddress"];
    [defaults setValue:self.serverPort.text forKey:@"serverPort"];
    [defaults setValue:self.jabberID.text forKey:@"jabberID"];
    [defaults setValue:self.password.text forKey:@"password"];
    
    // close the currenct connection and exchange it with the new one
    [AppDelegate sharedAppDelegate].xmppConnection = newConnection;
    
    // slide login view to right
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)showStatus:(NSString*)status {

    NSString * text = [NSString stringWithFormat:@"Status: %@", status];
    CGSize stringSize = [text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17.0] constrainedToSize:CGSizeMake(250.0f, 400.0f) lineBreakMode:NSLineBreakByWordWrapping];
    
    CGRect frame = self.status.frame;
    frame.size.height = stringSize.height;
    self.status.frame = frame;
    
    self.status.text = text;
}

@end
