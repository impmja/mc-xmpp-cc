//
//  ChatViewController.m
//  MC-XMPP-CC
//
//  Created by Jan Schulte on 16.04.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import "ChatViewController.h"
#import "ECSlidingViewController.h"

#import "AppDelegate.h"
#import "ChatTableViewCell.h"
#import "ChatTableViewCellSender.h"


@interface ChatViewController() {
    NSFetchedResultsController  *fetchedResultsController;
}
@end


@implementation ChatViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    // setup sliding view
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FriendsViewController class]]) {
        self.slidingViewController.underLeftViewController = [AppDelegate sharedAppDelegate].friendsViewController;
    }
   
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    self.view.keyboardTriggerOffset = self.toolBar.bounds.size.height;
    self.textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.textField.enablesReturnKeyAutomatically = YES;
    
    // Handles the transformation of the chat box and toolbar if the keyboard is shown or hid
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
    
    if (_receiverJID != nil) {
        [self showChatTableView:YES];
        [self scrollToBottom];
    } else {
        [self showChatTableView:NO];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    // Important: Must be removed if you use the keyboard within other views.
    // It otherwise will mess up the view you use the Keyboard panning action handler in.
    [self.view removeKeyboardControl];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {

    NSFetchedResultsController * frc = [self fetchedResultsController];
    if (frc != nil) {
        NSArray *sections = [frc sections];
        // get the rows within the current section
        if (sectionIndex < [sections count]) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            return sectionInfo.numberOfObjects;
        }
	}
    
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    XMPPMessageArchiving_Message_CoreDataObject *msg = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    NSString *cellText = msg.body;
    if (cellText == nil) {
        cellText = @"<Is typing ...>";
    }
    
    CGSize stringSize = [cellText sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17.0] constrainedToSize:CGSizeMake(250.0f, 400.0f) lineBreakMode:NSLineBreakByWordWrapping];
            
    return stringSize.height + 62;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XMPPMessageArchiving_Message_CoreDataObject *msg = [[self fetchedResultsController] objectAtIndexPath:indexPath];

    if (msg.isOutgoing) {
        ChatTableViewCellSender * cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCellSender"];
        if (cell == nil) {
            
            NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"ChatTableViewCell" owner:nil options:nil];
            
            for (id object in nib) {
                if ([object isKindOfClass:[ChatTableViewCellSender class]]) {
                    cell = (ChatTableViewCellSender *)object;
                    break;
                }
            }
        }
        
        cell.chatText.lineBreakMode = NSLineBreakByWordWrapping;
        cell.chatText.numberOfLines = 0;
        if (msg.body != nil) {
            cell.chatText.text = msg.body;
        } else {
            cell.chatText.text = @"<Is typing ...>";
        }
        
        XMPPJID * myJid = [AppDelegate sharedAppDelegate].xmppConnection.xmppStream.myJID;
        
        cell.avatarImage.image = [[AppDelegate sharedAppDelegate].xmppConnection findvCardImage:myJid];
        [cell.avatarImage.layer setBorderColor: [[UIColor blackColor] CGColor]];
        [cell.avatarImage.layer setBorderWidth: 2.0];
        [cell.avatarImage setClipsToBounds:YES];
        
        return cell;
    } else {
        ChatTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
        if (cell == nil) {
            
            NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"ChatTableViewCell" owner:nil options:nil];
            
            for (id object in nib) {
                if ([object isKindOfClass:[ChatTableViewCell class]]) {
                    cell = (ChatTableViewCell *)object;
                    break;
                }
            }
        }
        
        cell.chatText.lineBreakMode = NSLineBreakByWordWrapping;
        cell.chatText.numberOfLines = 0;
        if (msg.body != nil) {
            cell.chatText.text = msg.body;
        } else {
            cell.chatText.text = @"<Is typing ...>";        }
        
        cell.avatarImage.image = [[AppDelegate sharedAppDelegate].xmppConnection findvCardImage:msg.bareJid];
        [cell.avatarImage.layer setBorderColor: [[UIColor whiteColor] CGColor]];
        [cell.avatarImage.layer setBorderWidth: 2.0];
        [cell.avatarImage setClipsToBounds:YES];
        
        return cell;
    }
    
    return nil;
}


#pragma mark UITableViewCell helpers
-(void)scrollToBottom {
    [self.tableView reloadData];
    
    if (self.fetchedResultsController.fetchedObjects != nil && [self.fetchedResultsController.fetchedObjects count] > 0) {
        int lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
        NSIndexPath * ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}


#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {

    XMPPConnection * xmppConnection = [AppDelegate sharedAppDelegate].xmppConnection;
    
    // Create the FetchResultController if needed
	if (fetchedResultsController == nil && xmppConnection != nil) {
        NSManagedObjectContext * moc = xmppConnection.messageArchivingManagedObjectContext;
		
        // Set Entity on which to work on
		NSEntityDescription * entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor * sd = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
		NSArray * sortDescriptors = [NSArray arrayWithObjects:sd, nil];
		
		NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:20];    // most important property ;)
        
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:nil
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error]) {
			NSLog(@"Error performing fetch: %@", error);
		}
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self scrollToBottom];
}


#pragma mark Setter
-(void)setReceiverJID:(NSString *)jid {

    _receiverJID = jid;

    NSString * myJID = [AppDelegate sharedAppDelegate].xmppConnection.xmppStream.myJID.bare;
    [fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(bareJidStr == %@) AND (streamBareJidStr == %@)", _receiverJID, myJID]];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Error performing fetch: %@", error);
    } else {
        [self controllerDidChangeContent:fetchedResultsController];
    }
}


- (IBAction)onSendButtonClick:(id)sender {
    if (self.textField.text.length > 0) {
        [self.view hideKeyboard];
    
        // send message to the receiver jid
        [[AppDelegate sharedAppDelegate].xmppConnection sendMessage:self.textField.text toJID:_receiverJID];
        
        self.textField.text = @"";
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.textField.text.length > 0) {
        [self.view hideKeyboard];
    
        [[AppDelegate sharedAppDelegate].xmppConnection sendMessage:self.textField.text toJID:_receiverJID];
        
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
