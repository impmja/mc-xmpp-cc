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

@synthesize xmppStream, xmppReconnect, xmppRoster, xmppRosterStorage, xmppvCardTempModule, xmppvCardAvatarModule, xmppCapabilities, xmppCapabilitiesStorage;
@synthesize password, isConnected;



- (id) initWithHost:(NSString*)host andPort:(UInt16)port {
    if ((self = [super init])) {
        [self createStreamWithHost:host andPort:port];
    }
    
    return self;
}

- (void) dealloc {
    [self destroyStream];
}


- (void) createStreamWithHost:(NSString*)host andPort:(UInt16)port {
    
    // create XMPP Stream
    xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif

    // create & register XMPP Extensions
    xmppReconnect = [[XMPPReconnect alloc] init];
    
    // Setup Roster support
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    //xmppRoster [[[XMPPRoster alloc] init];
    xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	

    [xmppReconnect         activate:xmppStream];
	//[xmppRoster            activate:xmppStream];
	//[xmppvCardTempModule   activate:xmppStream];
	//[xmppvCardAvatarModule activate:xmppStream];
	//[xmppCapabilities      activate:xmppStream];
    
    // register delegates
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // setup host & port
    [xmppStream setHostName:host];
    [xmppStream setHostPort:port];
}

- (void) destroyStream {
    [xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
    
    [xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

- (BOOL) connectWithJID:(NSString*)_jid andPassword:(NSString*)_password {
	
    if (![xmppStream isDisconnected]) {
		return YES;
	}
   
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
    
	// A simple example of inbound message handling.
    
	if ([message isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:xmppStream
		                                               managedObjectContext:[self rosterManagedObjectContext]];
		
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


#pragma mark - Roster
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self rosterManagedObjectContext]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
	
}


#pragma mark Core Data
- (NSManagedObjectContext *)rosterManagedObjectContext {
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)capabilitiesManagedObjectContext {
	return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}


@end
