//
//  FriendsViewController.h
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface FriendsViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController  *fetchedResultsController;
}


@end
