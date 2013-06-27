//
//  ChatTableViewCellSender.h
//  test-app
//
//  Created by Jan Schulte and Florian Kaluschke on 16.04.13.
//  Copyright (c) 2013 Jan Schulte and Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>

//
//  ChatTableViewCellSender
//
//  Note: Used in ChatViewController for the Receiver Message
//
@interface ChatTableViewCellSender : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel        *chatText;
@property (weak, nonatomic) IBOutlet UIImageView    *avatarImage;

@end
