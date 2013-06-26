//
//  XMPPConnection.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "XMPPFramework.h"


@class XMPPConnection;


//
//  XMPPConnectionDelegate
//
//  Note: Delegate which is used in combination with the XMPPConnection class to enable a class to receive
//          Events like if a connection has succeeded or failed.
//
@protocol XMPPConnectionDelegate <NSObject>
@optional
- (void)onXMPPConnectionSucceeded:(XMPPConnection *)sender;
- (void)onXMPPConnectionFailed:(XMPPConnection *)sender withError:(NSError*) error;
@end



//
//  XMPPConnection
//
//  Note: This is the main class to work with an XMPPStream.
//          It encapsulates a XMPPStream and all extentions
//          we use in our APP. Namely:
//          *   Reconnect - Is used to reconnect to the XMPP Server if the connection was lost thru whatever reason
//          *   Roster - Is used to receive and keep information about all contacts (friends) one has
//          *   RosterStorage - Keeps all your Roster contacts within a local CoreData Database so the APP will have
//          *                   the last contacts available immediately after it was restarted. It is also used in combination
//          *                   with a FetchResultController to use it directely with a UITableView.
//          *   vCardTempModule - Keeps track of user specific information (vCard - virtual Card) of all contacts one has
//          *   vCardAvatarModule - Keeps track of of user images of all contacts one has
//          *   vCardCoreDataStorage - Keeps all previous vCard information within a local CoreData Database so the APP will have
//          *                   the user infromation/ image available immediately after it was restarted. It is also used in combination
//          *                   with a FetchResultController to use it directely with a UITableView.
//          *   MessageArchiving - Keeps track of all Messages a user has received and sent to a particular individual
//          *   MessageArchivingStorage - Stores all Messages in a CoreData Database so the APP will have
//          *                   all past received / sent Messages available immediately after it was restarted. It is also used in combination
//          *                   with a FetchResultController to use it directely with a UITableView.
//
@interface XMPPConnection : NSObject <XMPPRosterDelegate>

#pragma mark - XMPPStream
@property (nonatomic, strong, readonly) XMPPStream                              *xmppStream;

#pragma mark - XMPPStream Extensions (Modules)
@property (nonatomic, strong, readonly) XMPPReconnect                           *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster                              *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage               *xmppRosterStorage;             // persistent contacts data cache
@property (nonatomic, strong, readonly) XMPPvCardTempModule                     *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule                   *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage                *xmppvCardStorage;              // persistent contact data cache
@property (nonatomic, strong, readonly) XMPPMessageArchiving                    *xmppMessageArchiving;
@property (nonatomic, strong, readonly) XMPPMessageArchivingCoreDataStorage     *xmppMessageArchivingStorage;   // persistent message data cache

@property (nonatomic, assign, readonly) BOOL                                    isConnected;

@property (nonatomic, assign) id <XMPPConnectionDelegate>                       delegate;


#pragma mark - Initialization
- (id) initWithHost:(NSString*)host andPort:(UInt16)port;
- (void) dealloc;

#pragma mark - Interface
- (BOOL) connectWithJID:(NSString*)jid andPassword:(NSString*)password;
- (void) disconnect;

#pragma mark - CoreData Getter
- (NSManagedObjectContext *) rosterManagedObjectContext;
- (NSManagedObjectContext *) messageArchivingManagedObjectContext;

#pragma mark - Message Helper
- (void) sendMessage:(NSString *) messageStr toJID:(NSString*)jid;

#pragma vCard Helper
-(UIImage*) findvCardImage:(XMPPJID*)jid;

@end
