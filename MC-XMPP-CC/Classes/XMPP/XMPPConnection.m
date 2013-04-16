//
//  XMPPConnection.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import "XMPPConnection.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface XMPPConnection()

- (void)createStream;
- (void)destroyStream;

- (void)switchToOnline;
- (void)switchToOffline;

@end


@implementation XMPPConnection : NSObject {
    
    
}

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize password;
@synthesize isConnected;



- (id) init {
    if (!(self = [super init])) {
        [self createStream];
    }
    
    return self;
}

- (void) dealloc {
    [self destroyStream];
}


- (void) createStream {
    
    // create XMPP Stream
    xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif

    // create & register XMPP Extensions
    xmppReconnect = [[XMPPReconnect alloc] init];
    [xmppReconnect activate:xmppStream];
    
    // register delegates
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void) destroyStream {
    // cleanup
    [xmppStream removeDelegate:self];
    
    [xmppReconnect deactivate];
    
    [xmppStream disconnect];
	
	xmppStream = nil;
    xmppReconnect = nil;
}

- (BOOL) connectWithJID:(NSString*)_jid andPassword:(NSString*)_password {
	
    if (![xmppStream isDisconnected]) {
		return YES;
	}
    
    /*
	NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    */
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (_jid == nil || _password == nil) {
		return NO;
	}
    
	[xmppStream setMyJID:[XMPPJID jidWithString:_jid]];
	password = _password;
    
	NSError *error = nil;
	if (![xmppStream connect:&error]) {
        DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void) disconnect {
	[self switchToOffline];
	[xmppStream disconnect];
}


- (void)switchToOnline {
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[[self xmppStream] sendElement:presence];
}

- (void)switchToOffline {
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}


#pragma mark - Delegate Handling
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    /*
     if (allowSelfSignedCertificates)
     {
     [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
     }
     */
    
    /*
     if (allowSSLHostNameMismatch)
     {
     [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
     }
     else
     */
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"]) {
			if ([virtualDomain isEqualToString:@"gmail.com"]) {
				expectedCertName = virtualDomain;
			} else {
				expectedCertName = serverDomain;
			}
		} else if (serverDomain == nil) {
			expectedCertName = virtualDomain;
		} else {
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName) {
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	isConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:password error:&error]) {
		DDLogError(@"Error authenticating: %@", error);
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[self switchToOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    /*
	// A simple example of inbound message handling.
    
	if ([message isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:xmppStream
		                                               managedObjectContext:[self managedObjectContext_roster]];
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                                message:body
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
     */
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isConnected) {
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}



@end
