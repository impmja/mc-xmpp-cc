//
//  FriendTableViewCell.h
//  test-app
//
//  Created by Jan Schulte on 21.06.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>

//
//  FriendTableViewCell
//
//  Note: Used in FriendTableView for showing Friend (Contact) information
//
@interface FriendTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView    *friendImage;
@property (weak, nonatomic) IBOutlet UILabel        *friendName;

@end
