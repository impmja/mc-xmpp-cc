//
//  XMPPConnection.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "XMPPFramework.h"

/*
    TODO: - (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user {
    nach hier verschieben und aus den Controller aufrufen
*/

@interface XMPPConnection : NSObject <XMPPRosterDelegate> {
    NSString                            *password;
    BOOL                                isConnected;
}

@property (nonatomic, strong, readonly) XMPPStream                              *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect                           *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster                              *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage               *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule                     *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule                   *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage                *xmppvCardStorage;
@property (nonatomic, strong, readonly) XMPPCapabilities                        *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage         *xmppCapabilitiesStorage;
@property (nonatomic, strong, readonly) XMPPMessageArchivingCoreDataStorage     *xmppMessageArchivingStorage;
@property (nonatomic, strong, readonly) XMPPMessageArchiving                    *xmppMessageArchiving;


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
- (NSManagedObjectContext *)messageArchivingManagedObjectContext;

#pragma mark - Helper
- (void)sendMessage:(NSString *)messageStr toJID:(NSString*)jid;

#pragma avatar data
-(UIImage*)findvCardImage:(XMPPJID*)_jid;

@end
