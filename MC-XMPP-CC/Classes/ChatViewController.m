//
//  ChatViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte. All rights reserved.
//

#import "ChatViewController.h"
#import "ECSlidingViewController.h"

#import "AppDelegate.h"


@interface ChatViewController ()

@end

@implementation ChatViewController


#pragma mark Accessors
- (AppDelegate*)appDelegate {
	return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController = appDelegate.friendsViewController;
    }
    
    /*
    if (![self.slidingViewController.underRightViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underRightViewController = appDelegate.friendsViewController;
    }
    */
    
    //[self.view addGestureRecognizer:self.slidingViewController.panGesture];
    self.slidingViewController.anchorLeftPeekAmount = 40;
    self.slidingViewController.anchorLeftRevealAmount = 320.0f;
    self.slidingViewController.anchorRightPeekAmount = 40;
    self.slidingViewController.anchorRightRevealAmount = 320.0f;
    
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    self.view.keyboardTriggerOffset = self.toolBar.bounds.size.height;
    
    __weak ChatViewController * bSelf = self;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        CGRect toolBarFrame = bSelf.toolBar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        bSelf.toolBar.frame = toolBarFrame;
        
        CGRect tableViewFrame = bSelf.tableView.frame;
        tableViewFrame.size.height = toolBarFrame.origin.y;
        
        bSelf.tableView.frame = tableViewFrame;
        
        [bSelf scrollToBottom];
    }];
    
    [self scrollToBottom];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
	
	XMPPMessageArchiving_Message_CoreDataObject *msg = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	
    if (msg.body != nil) {
        cell.textLabel.text = msg.body;
    } else {
        cell.textLabel.text = @"<Ist am tippen ...>";
    }
	
	[self configurePhotoForCell:cell withJID:msg.bareJid];
    
    return cell;
}


#pragma mark UITableViewCell helpers
- (void)configurePhotoForCell:(UITableViewCell *)cell withJID:(XMPPJID *)jid {
	if (jid == nil) {
		cell.imageView.image = nil; // TODO: Default?
	} else {
		NSData *photoData = [[[[self appDelegate] xmppConnection] xmppvCardAvatarModule] photoDataForJID:jid];
        
		if (photoData != nil)
			cell.imageView.image = [UIImage imageWithData:photoData];
		else
			cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
	}
}

-(void)scrollToBottom {
    [self.tableView reloadData];
    int lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
    NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
}


#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {
	if (fetchedResultsController == nil) {
		NSManagedObjectContext *moc = [[self appDelegate] xmppConnection].messageArchivingManagedObjectContext;
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		//[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:nil
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
    
    [self scrollToBottom];
}


#pragma mark Setter
-(void)setCurrentJID:(NSString *)jid {

    _currentJID = jid;

    [fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"bareJidStr == %@", _currentJID]];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        //DDLogError(@"Error performing fetch: %@", error);
    } else {
        [self controllerDidChangeContent:fetchedResultsController];
    }
}


- (IBAction)onSendButtonClick:(id)sender {
    if (self.textField.text.length > 0) {
        [self.view hideKeyboard];
    
        [[[self appDelegate] xmppConnection] sendMessage:self.textField.text toJID:self.currentJID];
        
        self.textField.text = @"";
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.textField.text.length > 0) {
        [self.view hideKeyboard];
    
        [[[self appDelegate] xmppConnection] sendMessage:self.textField.text toJID:self.currentJID];
        
        self.textField.text = @"";
        
        [self.textField resignFirstResponder];
        return YES;
    }
    return NO;
}

@end
