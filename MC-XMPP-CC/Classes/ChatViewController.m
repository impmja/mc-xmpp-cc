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
#import "ChatTableViewCell.h"


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
    
    if (_currentJID != nil) {
        [self showChatTableView:YES];
        [self scrollToBottom];
    } else {
        [self showChatTableView:NO];
    }
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



#define kTimelineTextFieldWidth 250.0f
#define kMaxTimelineTextFieldHeight 400.0f

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *msg = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    NSString *cellText = msg.body;

    CGSize stringSize = [cellText sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17.0] constrainedToSize:CGSizeMake(kTimelineTextFieldWidth, kMaxTimelineTextFieldHeight) lineBreakMode:NSLineBreakByWordWrapping];
            
    return stringSize.height + 62;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ChatCell";
	
    ChatTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"ChatTableViewCell" owner:nil options:nil];
        
        for (id object in nib) {
            if ([object isKindOfClass:[ChatTableViewCell class]]) {
                cell = (ChatTableViewCell *)object;
                break;
            }
        }
    }

	XMPPMessageArchiving_Message_CoreDataObject *msg = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	cell.chatText.lineBreakMode = NSLineBreakByWordWrapping;
    cell.chatText.numberOfLines = 0;
    if (msg.body != nil) {
        cell.chatText.numberOfLines = 0;
        //cell.chatText.text = [NSString stringWithFormat:@"JIB: %@ - Text:%@", msg.bareJidStr, msg.body];
        cell.chatText.text = msg.body;
        cell.chatText.font = [UIFont fontWithName:@"Helvetica" size:17.0f];

        
    } else {
        cell.chatText.text = @"<Ist am tippen ...>"; // TODO: Localize
    }
	
    if (!msg.isOutgoing) {
        [self configurePhotoForCell:cell withJID:msg.bareJid];
    }
    return cell;
}


#pragma mark UITableViewCell helpers
- (void)configurePhotoForCell:(ChatTableViewCell *)cell withJID:(XMPPJID *)jid {
    [cell.avatarImage setClipsToBounds:YES];
	if (jid == nil) {
		cell.avatarImage.image = [UIImage imageNamed:@"defaultAvatarImage"];
	} else {
		NSData *photoData = [[[[self appDelegate] xmppConnection] xmppvCardAvatarModule] photoDataForJID:jid];
		if (photoData != nil) {
			cell.avatarImage.image = [UIImage imageWithData:photoData];
        } else {
			cell.avatarImage.image = [UIImage imageNamed:@"defaultAvatarImage"];
        }
	}
}

-(void)scrollToBottom {
    [self.tableView reloadData];
    
    if (self.fetchedResultsController.fetchedObjects != nil && [self.fetchedResultsController.fetchedObjects count] > 0) {
        int lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
        NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
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
    
    if (_currentJID != nil) {
       [self showChatTableView:YES];
    } else {
       [self showChatTableView:YES];
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


-(void)showChatTableView:(BOOL)show {
    [self.noConversationView setHidden:show];
    [self.tableView setHidden:!show];
    [self.toolBar setHidden:!show];
}


@end
