//
//  FriendsViewController.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte and Florian Kaluschke on 16.04.13.
//  Copyright (c) 2013 Jan Schulte and Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

//
//  FriendsViewController
//
//  Note: Is used to chat with the selected friend. It also shows the history of messages, if there are any.
//
@interface FriendsViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@end
