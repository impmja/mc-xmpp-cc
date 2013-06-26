//
//  FriendsViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import "FriendsViewController.h"
#import "ECSlidingViewController.h"
#import "AppDelegate.h"
#include "FriendTableViewCell.h"


@interface FriendsViewController () {
    NSFetchedResultsController  *fetchedResultsController;
}
@end


@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // slide chat view to right
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)viewWillAppear:(BOOL)animated {

    [self setFriendListOwnerJID: [AppDelegate sharedAppDelegate].xmppConnection.xmppStream.myJID.bare];
}


#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {

    // Check if there is a connection and only then create the fetch controller otherewise show only the options menu
    XMPPConnection * xmppConnection = [AppDelegate sharedAppDelegate].xmppConnection;
    
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
		[fetchRequest setFetchBatchSize:20];    // most important property ;)
        
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
        [self setFriendListOwnerJID: [AppDelegate sharedAppDelegate].xmppConnection.xmppStream.myJID.bare];
    }
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[[self tableView] reloadData];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(00, 0, tableView.bounds.size.width, 40)];
    [headerView setBackgroundColor:[UIColor blackColor]];
    
    // get section header text
    NSString * headerText = nil;
    NSFetchedResultsController * frc = [self fetchedResultsController];
    if (frc == nil) {
        headerText = @"Options";
    } else {
        NSArray *sections = [frc sections];
        if (section < [sections count]) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
            
            int section = [sectionInfo.name intValue];
            switch (section) {
                case 0  : headerText = @"Available"; break;
                case 1  : headerText = @"Away"; break;
                default : headerText = @"Offline"; break;
            }
        } else {
            headerText = @"Options";
        }
    }
    
    // Change section header font and color
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, tableView.bounds.size.width - 10, 30)];
    label.text = headerText;
    label.font = [UIFont fontWithName:@"Helvetica" size:30.0f];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [headerView addSubview:label];

    return headerView;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // create specific friend view cell
    FriendTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    if (cell == nil) {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"FriendTableViewCell" owner:nil options:nil];
        
        for (id object in nib) {
            if ([object isKindOfClass:[FriendTableViewCell class]]) {
                cell = (FriendTableViewCell *)object;
                UIView *v = [[UIView alloc] init];
                v.backgroundColor = [UIColor blackColor];
                cell.selectedBackgroundView = v;
                break;
            }
        }
    }
    
    if (indexPath.section < [[self fetchedResultsController] sections].count) {
        XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        if (user.nickname != nil && [user.nickname length] > 0) {
            if (user.unreadMessages != nil && [user.unreadMessages intValue] > 0) {
                cell.friendName.text = [NSString stringWithFormat:@"%@ (%@)", user.nickname, user.unreadMessages];
            } else {
                cell.friendName.text = user.nickname;
            }
        } else {
            // remove server name
            NSArray * strings = [user.displayName componentsSeparatedByString: @"@"];
            NSString * name = [strings count] > 0 ? [strings objectAtIndex:0] : user.displayName;
            
            if (user.unreadMessages != nil && [user.unreadMessages intValue] > 0) {
                cell.friendName.text = [NSString stringWithFormat:@"%@ (%@)", name, user.unreadMessages];
            } else {
                cell.friendName.text = name;
            }
        }
        
         cell.friendImage.image = [[AppDelegate sharedAppDelegate].xmppConnection findvCardImage:user.jid];
	} else {
        cell.friendName.text = @"Login";
        cell.friendImage.image = [UIImage imageNamed:@"settings.png"];
    }
    
    [cell.friendImage.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [cell.friendImage.layer setBorderWidth: 2.0];
    
	return cell;
}

#pragma mark Setter
-(void)setFriendListOwnerJID:(NSString *)jid {

    if (fetchedResultsController == nil) {
        return;
    }
    
    // Note: Does not work... fliters wrong..
    //NSString * myJID = [AppDelegate sharedAppDelegate].xmppConnection.xmppStream.myJID.bare;
    //[fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(streamBareJidStr == %@)", myJID]];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Error performing fetch: %@", error);
    } else {
        [self controllerDidChangeContent:fetchedResultsController];
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSFetchedResultsController * frc = [self fetchedResultsController];
    
    // get the selected user and set it as a filter for the chat
    if (frc != nil && indexPath.section < [frc sections].count) {
        XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        [[AppDelegate sharedAppDelegate].chatViewController setReceiverJID:[user.jid full]];
        
        // slide to chat view
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
             CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = [AppDelegate sharedAppDelegate].chatViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    } else {
        // slide to login view
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = [AppDelegate sharedAppDelegate].loginViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    }
    
    // change image border to selcted state
    FriendTableViewCell * cell = (FriendTableViewCell*)  [tableView cellForRowAtIndexPath:indexPath];
    [cell.friendImage.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [cell.friendImage.layer setBorderWidth: 2.0];
}


-(void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    // change image border to deselected state
    FriendTableViewCell * cell = (FriendTableViewCell*)  [tableView cellForRowAtIndexPath:indexPath];
    [cell.friendImage.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [cell.friendImage.layer setBorderWidth: 2.0];
}

@end
