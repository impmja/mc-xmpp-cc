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
    XMPPStream          *xmppStream;
    XMPPReconnect       *xmppReconnect;
    NSString            *password;
    BOOL                isConnected;
}

@property (nonatomic, strong, readonly) XMPPStream      *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect   *xmppReconnect;
@property (nonatomic, strong, readonly) NSString        *password;
@property (nonatomic, assign, readonly) BOOL            isConnected;


#pragma mark - Initialization
- (id) init;
- (void) dealloc;

#pragma mark - Interface
- (BOOL) connectWithJID:(NSString*)_jid andPassword:(NSString*)_password;
- (void) disconnect;

@end
