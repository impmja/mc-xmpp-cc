//
//  FriendTableViewCell.h
//  test-app
//
//  Created by Jan Schulte and Florian Kaluschke on 16.04.13.
//  Copyright (c) 2013 Jan Schulte and Florian Kaluschke. All rights reserved.
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
