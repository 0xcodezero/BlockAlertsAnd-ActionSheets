//
//  GTAlertView.m
//  BlockAlertsDemo
//
//  Created by Ahmed Ghalab on 4/26/14.
//  Copyright (c) 2014 CodeCrop Software. All rights reserved.
//

#import "GTAlertView.h"

@implementation GTAlertView

+ (GTAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message
{
    return [[[GTAlertView alloc] initWithTitle:title message:message] autorelease];
}

+ (void)showInfoAlertWithTitle:(NSString *)title message:(NSString *)message
{
    GTAlertView *alert = [[GTAlertView alloc] initWithTitle:title message:message];
    [alert setCancelButtonWithTitle:NSLocalizedString(@"Dismiss", nil) block:nil];
    [alert show];
    [alert release];
}

+ (void)showErrorAlert:(NSError *)error
{
    GTAlertView *alert = [[GTAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The operation did not complete successfully: %@", nil), error]];
    [alert setCancelButtonWithTitle:@"Dismiss" block:nil];
    [alert show];
    [alert release];
}

@end
