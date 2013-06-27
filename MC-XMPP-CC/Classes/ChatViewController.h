//
//  ChatViewController.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte and Florian Kaluschke on 16.04.13.
//  Copyright (c) 2013 Jan Schulte and Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "DAKeyboardControl.h"


// Messages parsen: http://stackoverflow.com/questions/14628078/going-through-text-parsing-links


//
//  ChatViewController
//
//  Note: Is used to chat with the selected friend. It also shows the history of messages, if there are any.
//
@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) NSString                    *receiverJID;

@property (weak, nonatomic) IBOutlet UITableView        *tableView;
@property (weak, nonatomic) IBOutlet UIView             *toolBar;
@property (weak, nonatomic) IBOutlet UIButton           *sendButton;
@property (weak, nonatomic) IBOutlet UITextField        *textField;
@property (weak, nonatomic) IBOutlet UIView             *noConversationView;

@end
