//
//  ChatTableViewCellSender.h
//  test-app
//
//  Created by Florian Kaluschke on 14.06.13.
//  Copyright (c) 2013 Jan Schulte, Florian Kaluschke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatTableViewCellSender : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *chatText;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;

@end
