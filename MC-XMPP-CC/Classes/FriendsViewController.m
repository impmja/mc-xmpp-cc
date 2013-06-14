//
//  FriendsViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import "FriendsViewController.h"
#import "ECSlidingViewController.h"
#import "AppDelegate.h"


@interface FriendsViewController () 
@end

#define kOptionsSection 


@implementation FriendsViewController

#pragma mark Accessors
- (AppDelegate*)appDelegate {
	return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slidingViewController.anchorRightRevealAmount = 280.0f;
    self.slidingViewController.underRightWidthLayout = ECFullWidth;
    
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)viewWillAppear:(BOOL)animated {
    self.slidingViewController.anchorRightRevealAmount = 280.0f;
    self.slidingViewController.underRightWidthLayout = ECFullWidth;
}


#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {
    XMPPConnection * xmppConnection = [[self appDelegate] xmppConnection];
    
	if (fetchedResultsController == nil && xmppConnection != nil) {
		NSManagedObjectContext *moc = xmppConnection.rosterManagedObjectContext;
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error]) {
			//DDLogError(@"Error performing fetch: %@", error);
		}
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[[self tableView] reloadData];
}


#pragma mark UITableViewCell helpers
- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user {
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
	if (user.photo != nil) {
		cell.imageView.image = user.photo;
	} else {
		NSData *photoData = [[[[self appDelegate] xmppConnection] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil)
			cell.imageView.image = [UIImage imageWithData:photoData];
		else
			cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
	}
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSFetchedResultsController * frc = [self fetchedResultsController];
    if (frc != nil) {
        return [[frc sections] count] + 1; // +1 for Options
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex {
	
    NSFetchedResultsController * frc = [self fetchedResultsController];
    if (frc == nil) {
        return @"Options";
    }
    
    NSArray *sections = [frc sections];
	if (sectionIndex < [sections count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
		int section = [sectionInfo.name intValue];
		switch (section) {
			case 0  : return @"Available";
			case 1  : return @"Away";
			default : return @"Offline";
		}
	} else {
        return @"Options";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	} else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
	
    //NSLog(@"Sections: %d - Section: %d", [[self fetchedResultsController] sections].count, indexPath.section);
    
    if (indexPath.section < [[self fetchedResultsController] sections].count) {
        XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        if (user.nickname != nil && [user.nickname length] > 0) {
            if (user.unreadMessages != nil && [user.unreadMessages intValue] > 0) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", user.nickname, user.unreadMessages];
            } else {
                cell.textLabel.text = user.nickname;
            }
        } else {
            if (user.unreadMessages != nil && [user.unreadMessages intValue] > 0) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", user.displayName, user.unreadMessages];
            } else {
                cell.textLabel.text = user.displayName;
            }
        }
        
         cell.imageView.image = [[[self appDelegate] xmppConnection] findvCardImage:user.jid];
        //[self configurePhotoForCell:cell user:user];
	} else {
        cell.textLabel.text = @"Login";
        cell.imageView.image = [UIImage imageNamed:@"bitch_please.png"];
    }
    
	return cell;
}



#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSFetchedResultsController * frc = [self fetchedResultsController];
    
    // get the selected user & set it as a filter for the chat
    if (frc != nil && indexPath.section < [frc sections].count) {
        XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        [[self appDelegate].chatViewController setCurrentJID:[user.jid full]];
        
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
             CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = [self appDelegate].chatViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    } else {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = [self appDelegate].loginViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    }
}

@end
