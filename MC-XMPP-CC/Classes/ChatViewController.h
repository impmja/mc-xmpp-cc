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

// Messages parsen: http://stackoverflow.com/questions/14628078/going-through-text-parsing-links

@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController  *fetchedResultsController;
}

@property (nonatomic, strong) NSString                  *currentJID;

@property (weak, nonatomic) IBOutlet UITableView        *tableView;
@property (weak, nonatomic) IBOutlet UIView             *toolBar;
@property (weak, nonatomic) IBOutlet UIButton           *sendButton;
@property (weak, nonatomic) IBOutlet UITextField        *textField;
@property (weak, nonatomic) IBOutlet UIView *noConversationView;

@end
