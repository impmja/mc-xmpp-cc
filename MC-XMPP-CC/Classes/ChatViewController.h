//
//  ChatViewController.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "DAKeyboardControl.h"


// Chat Messages in History speichern/laden: http://stackoverflow.com/questions/8568910/storing-messages-using-xmppframework-for-ios
@interface ChatViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController  *fetchedResultsController;
}

@property (nonatomic, strong) NSString             *currentJID;


@end
