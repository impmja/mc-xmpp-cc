//
//  XMPPConnection.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import "XMPPConnection.h"


//
//  Internal (private) Methods of the XMPPConnection class
//
@interface XMPPConnection() {
    NSString       *authPassword;
}

- (void) createStreamWithHost:(NSString*)host andPort:(UInt16)port;
- (void)destroyStream;
- (void)switchToOnline;
- (void)switchToOffline;

@end


@implementation XMPPConnection

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster, xmppRosterStorage;
@synthesize xmppvCardTempModule, xmppvCardAvatarModule, xmppvCardStorage;
@synthesize xmppMessageArchivingStorage, xmppMessageArchiving;

@synthesize isConnected;



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
    
    // Create XMPP Stream
    xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif

    // Setup Reconnect support
    xmppReconnect = [[XMPPReconnect alloc] init];
    
    // Setup Roster support
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    //xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:nil];
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	//[xmppRoster fetchRoster];
    
	// Setup vCard support
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
    // Setup User Photos
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
    // Setup Message Archive
    xmppMessageArchivingStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:xmppMessageArchivingStorage];
    // Store messages on client side only
    [xmppMessageArchiving setClientSideMessageArchivingOnly:YES];

    // activate modules (extentions)
    [xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
	[xmppvCardTempModule   activate:xmppStream];
	[xmppvCardAvatarModule activate:xmppStream];
    [xmppMessageArchiving  activate:xmppStream];
    
    // register delegates
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppMessageArchiving addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // setup host & port
    [xmppStream setHostName:host];
    [xmppStream setHostPort:port];
}

- (void) destroyStream {
    [xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	[xmppMessageArchiving removeDelegate:self];
    
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	
    [xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
}

- (BOOL) connectWithJID:(NSString*)jid andPassword:(NSString*)password {
	
    if (![xmppStream isDisconnected]) {
		return YES;
	}
   
	if (jid == nil || password == nil) {
		return NO;
	}
    
	[xmppStream setMyJID:[XMPPJID jidWithString:jid]];
	authPassword = password;
    
	NSError *error = nil;
	if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        NSLog(@"Error connecting: %@", error);
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


#pragma mark - Callback Handler
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
    
    NSString *expectedCertName = nil;
    NSString *serverDomain = xmppStream.hostName;
    NSString *virtualDomain = [xmppStream.myJID domain];
    
    // special handling while connection to google-talk servers
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

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	isConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:authPassword error:&error]) {
		NSLog(@"Error authenticating: %@", error);
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	[self switchToOnline];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onXMPPConnectionSucceeded:)] ) {
        [self.delegate onXMPPConnectionSucceeded:self];
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onXMPPConnectionFailed:withError:)] ) {
        [self.delegate onXMPPConnectionFailed:self withError:[NSError errorWithDomain:@"XMPPConnection" code:1 userInfo:[NSDictionary dictionaryWithObjects:@[@"Failed to authenticate."] forKeys:@[NSLocalizedDescriptionKey]]]];
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
	if (self.delegate && [self.delegate respondsToSelector:@selector(onXMPPConnectionFailed:withError:)] ) {
        [self.delegate onXMPPConnectionFailed:self withError:[NSError errorWithDomain:@"XMPPConnection" code:1 userInfo:[NSDictionary dictionaryWithObjects:@[@"Failed to connect."] forKeys:@[NSLocalizedDescriptionKey]]]];
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
	if (!isConnected && self.delegate && [self.delegate respondsToSelector:@selector(onXMPPConnectionFailed:withError:)] ) {
        [self.delegate onXMPPConnectionFailed:self withError:[NSError errorWithDomain:@"XMPPConnection" code:1 userInfo:[NSDictionary dictionaryWithObjects:@[@"Unable to connect to server."] forKeys:@[NSLocalizedDescriptionKey]]]];
    }
}


#pragma mark - Roster
/*
// Not used for now, as we wanted a rather simple chat client
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self rosterManagedObjectContext]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare]) {
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else {
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
    
        NSLog(@"Message: %@", body);
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	} else {
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
}
*/


#pragma mark - Core Data - Getter
- (NSManagedObjectContext *) rosterManagedObjectContext {
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *) messageArchivingManagedObjectContext {
	return [xmppMessageArchivingStorage mainThreadManagedObjectContext];
}


#pragma mark - Message Helper
- (void) sendMessage:(NSString *)messageStr toJID:(NSString*)jid {

    if([messageStr length] > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];

        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:jid];
        [message addChild:body];

        [xmppStream sendElement:message];
    }
}


#pragma vCard Helper
-(UIImage*) findvCardImage:(XMPPJID*)jid {
    NSData *photoData = [self.xmppvCardAvatarModule photoDataForJID:jid];
    if (photoData != nil) {
        return [UIImage imageWithData:photoData];
    } else {
        return [UIImage imageNamed:@"defaultAvatarImage"];
    }
}


@end
