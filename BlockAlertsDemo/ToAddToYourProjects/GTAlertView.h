//
//  GTAlertView.h
//  BlockAlertsDemo
//
//  Created by Ahmed Ghalab on 4/26/14.
//  Copyright (c) 2014 CodeCrop Software. All rights reserved.
//

#import "BlockAlertView.h"

@interface GTAlertView : BlockAlertView

+ (GTAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message;

+ (void)showInfoAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showErrorAlert:(NSError *)error;

@end
