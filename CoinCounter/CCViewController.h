//
//  CCViewController.h
//  CoinCounter
//
//  Created by Test user on 2/25/13.
//  Copyright (c) 2013 UNIT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>


@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIImageView *finalImage;
- (IBAction)takeAShot:(id)sender;

@end
