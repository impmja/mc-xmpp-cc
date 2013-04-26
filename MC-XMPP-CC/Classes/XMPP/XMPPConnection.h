//
//  XMPPConnection.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPFramework.h"


@interface XMPPConnection : NSObject {
    XMPPStream                          *xmppStream;
    XMPPReconnect                       *xmppReconnect;
    XMPPRoster                          *xmppRoster;
	XMPPRosterCoreDataStorage           *xmppRosterStorage;
    XMPPvCardCoreDataStorage            *xmppvCardStorage;
	XMPPvCardTempModule                 *xmppvCardTempModule;
	XMPPvCardAvatarModule               *xmppvCardAvatarModule;
	XMPPCapabilities                    *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage     *xmppCapabilitiesStorage;
    
    NSString                            *password;
    BOOL                                isConnected;
}

@property (nonatomic, strong, readonly) XMPPStream                          *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect                       *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster                          *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage           *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule                 *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule               *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities                    *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage     *xmppCapabilitiesStorage;


@property (nonatomic, strong, readonly) NSString        *password;
@property (nonatomic, assign, readonly) BOOL            isConnected;


#pragma mark - Initialization
- (id) initWithHost:(NSString*)host andPort:(UInt16)port;
- (void) dealloc;

#pragma mark - Interface
- (BOOL) connectWithJID:(NSString*)_jid andPassword:(NSString*)_password;
- (void) disconnect;

#pragma mark - CoreData
- (NSManagedObjectContext *)rosterManagedObjectContext;
- (NSManagedObjectContext *)capabilitiesManagedObjectContext;

@end
