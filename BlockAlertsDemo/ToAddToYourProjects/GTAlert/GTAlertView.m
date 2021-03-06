//
//  GTAlertView.m
//  BlockAlertsDemo
//
//  Created by Ahmed Ghalab on 4/26/14.
//  Copyright (c) 2014 CodeCrop Software. All rights reserved.
//


#import "GTAlertView.h"
#import "BlockUI.h"
#import "BlurBackground.h"
#import "UIColor+GTAlert.h"
#import "BlockAlertView.h"

@implementation GTAlertView

@synthesize backgroundImage = _backgroundImage;
@synthesize vignetteBackground = _vignetteBackground;

static UIImage *background = nil;
static UIImage *backgroundlandscape = nil;
static UIFont *titleFont = nil;
static UIFont *messageFont = nil;
static UIFont *buttonFont = nil;

#pragma mark - init

+ (void)initialize
{
    if (self == [GTAlertView class])
    {
        background = [UIImage imageNamed:kAlertViewBackground];
        background = [[background stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight] retain];
        
        backgroundlandscape = [UIImage imageNamed:kAlertViewBackgroundLandscape];
        backgroundlandscape = [[backgroundlandscape stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight] retain];
        
        titleFont = [kAlertViewTitleFont retain];
        messageFont = [kAlertViewMessageFont retain];
        buttonFont = [kAlertViewButtonFont retain];
    }
}

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

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (void)setupDisplay
{
    [[_view subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    
    UIWindow *parentView = [BlurBackground sharedInstance];
    CGRect frame = parentView.bounds;
    frame.origin.x = floorf((frame.size.width - background.size.width) * 0.5);
    frame.size.width = background.size.width;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        frame.size.width += 150;
        frame.origin.x -= 75;
    }
    
    _view.frame = frame;
    
    _height = kAlertViewBorder + 15;
    
    if (NeedsLandscapePhoneTweaks) {
        _height -= 15; // landscape phones need to trimmed a bit
    }
    
    [self addComponents:frame];
    
    if (_shown)
        [self show];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    self = [super init];
    
    if (self)
    {
        _title = [title copy];
        _message = [message copy];
        
        _view = [[UIView alloc] init];
        
        _view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        _blocks = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setupDisplay)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        
        if ([self class] == [GTAlertView class])
            [self setupDisplay];
        
        _vignetteBackground = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)show
{
    _shown = YES;
    
    BOOL isSecondButton = NO;
    NSUInteger index = 0;
    for (NSUInteger i = 0; i < _blocks.count; i++)
    {
        NSArray *block = [_blocks objectAtIndex:i];
        NSString *title = [block objectAtIndex:1];
        NSString *color = [block objectAtIndex:2];
        
        UIImage *image = nil;//[UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button.png", color]];
        image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
        
        UIImage *highlightedImage = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button-highlighted.png", color]];
        
        highlightedImage = [highlightedImage stretchableImageWithLeftCapWidth:(int)(highlightedImage.size.width+1)>>1 topCapHeight:0];
        
		CGFloat maxHalfWidth = floorf(_view.bounds.size.width*0.5);
        CGFloat width = _view.bounds.size.width;
        CGFloat xOffset = 0;
        if (isSecondButton)
        {
            width = maxHalfWidth;
            xOffset = width;
            isSecondButton = NO;
        }
        else if (i + 1 < _blocks.count)
        {
            // In this case there's another button.
            // Let's check if they fit on the same line.
            CGSize size = [title sizeWithFont:buttonFont
                                  minFontSize:10
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width
                                lineBreakMode:NSLineBreakByClipping];
            
            if (size.width < maxHalfWidth)
            {
                // It might fit. Check the next Button
                NSArray *block2 = [_blocks objectAtIndex:i+1];
                NSString *title2 = [block2 objectAtIndex:1];
                size = [title2 sizeWithFont:buttonFont
                                minFontSize:10
                             actualFontSize:nil
                                   forWidth:_view.bounds.size.width
                              lineBreakMode:NSLineBreakByClipping];
                
                if (size.width < maxHalfWidth)
                {
                    // They'll fit!
                    isSecondButton = YES;  // For the next iteration
                    width = maxHalfWidth;
                }
            }
        }
        else if (_blocks.count  == 1)
        {
            // In this case this is the ony button. We'll size according to the text
            CGSize size = [title sizeWithFont:buttonFont
                                  minFontSize:10
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width
                                lineBreakMode:NSLineBreakByClipping];
            
            size.width = MAX(size.width, 80);
            if (size.width < width)
            {
                width = size.width;
                xOffset = floorf((_view.bounds.size.width - width) * 0.5);
            }
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(xOffset, _height, width, kAlertButtonHeight);
        button.titleLabel.font = buttonFont;
        if (IOS_LESS_THAN_6) {
#pragma clan diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            button.titleLabel.minimumFontSize = 10;
#pragma clan diagnostic pop
        }
        else {
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.adjustsLetterSpacingToFitWidth = YES;
            button.titleLabel.minimumScaleFactor = 0.1;
        }
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.shadowOffset = kAlertViewButtonShadowOffset;
        button.backgroundColor = [UIColor clearColor];
        button.tag = i+1;
        
		
		UIColor *whiteColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.3];
		button.layer.borderColor = whiteColor.CGColor;
		button.layer.borderWidth = 1.f / [[UIScreen mainScreen] scale];
		
		if([color isEqualToString:@"red"])
		{
			[button setTitleColor:[UIColor bb_dangerColorV3] forState:UIControlStateNormal];
			[button setTitleColor:[UIColor bb_dangerColorV2] forState:UIControlStateHighlighted];
		}
		else if([color isEqualToString:@"green"])
		{
			[button setTitleColor:[UIColor bb_infoColorV3] forState:UIControlStateNormal];
			[button setTitleColor:[UIColor bb_infoColorV2] forState:UIControlStateHighlighted];
		}
		else if([color isEqualToString:@"gray"])
		{
			[button setTitleColor:[UIColor bb_grayBButtonColor] forState:UIControlStateNormal];
			[button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
		}
		else if([color isEqualToString:@"yellow"])
		{
			[button setTitleColor:[UIColor bb_warningColorV3] forState:UIControlStateNormal];
			[button setTitleColor:[UIColor bb_warningColorV2] forState:UIControlStateHighlighted];
		}
		else
		{
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			[button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
		}
        
        [button setTitleShadowColor:kAlertViewButtonShadowColor forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal];
        button.accessibilityLabel = title;
        
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [_view addSubview:button];
        
        if (!isSecondButton)
            _height += kAlertButtonHeight;
        
        index++;
    }
    
    //_height += 10;  // Margin for the shadow // not sure where this came from, but it's making things look strange (I don't see a shadow, either)
    
    if (_height < background.size.height)
    {
        CGFloat offset = background.size.height - _height;
        _height = background.size.height;
        CGRect frame;
        for (NSUInteger i = 0; i < _blocks.count; i++)
        {
            UIButton *btn = (UIButton *)[_view viewWithTag:i+1];
            frame = btn.frame;
            frame.origin.y += offset;
            btn.frame = frame;
        }
    }
    
    
    CGRect frame = _view.frame;
    frame.origin.y = - _height;
    frame.size.height = _height;
    _view.frame = frame;
    
    UIImageView *modalBackground = [[UIImageView alloc] initWithFrame:_view.bounds];
    
	UIColor *whiteColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.000];
	
	_view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0f];
	_view.layer.borderColor = whiteColor.CGColor;
	_view.layer.borderWidth = 1.f;
	_view.layer.cornerRadius = 10.f;
	_view.clipsToBounds = YES;
	
    modalBackground.contentMode = UIViewContentModeScaleToFill;
    modalBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_view insertSubview:modalBackground atIndex:0];
    [modalBackground release];
    
    if (_backgroundImage)
    {
        [BlurBackground sharedInstance].backgroundImage = _backgroundImage;
        [_backgroundImage release];
        _backgroundImage = nil;
    }
    
    [BlurBackground sharedInstance].vignetteBackground = _vignetteBackground;
    [[BlurBackground sharedInstance] addToMainWindow:_view];
    
    __block CGPoint center = _view.center;
    center.y = floorf([BlurBackground sharedInstance].bounds.size.height * 0.5) + kAlertViewBounce;
    
    _cancelBounce = NO;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [BlurBackground sharedInstance].alpha = 1.0f;
                         _view.center = center;
                     }
                     completion:^(BOOL finished) {
                         if (_cancelBounce) return;
                         
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:0
                                          animations:^{
                                              center.y -= kAlertViewBounce;
                                              _view.center = center;
                                          }
                                          completion:^(BOOL finished) {
                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"AlertViewFinishedAnimations" object:self];
                                          }];
                     }];
    
    [self retain];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    _shown = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (buttonIndex >= 0 && buttonIndex < [_blocks count])
    {
        id obj = [[_blocks objectAtIndex: buttonIndex] objectAtIndex:0];
        if (![obj isEqual:[NSNull null]])
        {
            ((void (^)())obj)();
        }
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:0
                         animations:^{
                             CGPoint center = _view.center;
                             center.y += 20;
                             _view.center = center;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.4
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseIn
                                              animations:^{
                                                  CGRect frame = _view.frame;
                                                  frame.origin.y = -frame.size.height;
                                                  _view.frame = frame;
                                                  [[BlurBackground sharedInstance] reduceAlphaIfEmpty];
                                              }
                                              completion:^(BOOL finished) {
                                                  [[BlurBackground sharedInstance] removeView:_view];
                                                  [_view release]; _view = nil;
                                                  [self autorelease];
                                              }];
                         }];
    }
    else
    {
        [[BlurBackground sharedInstance] removeView:_view];
        [_view release]; _view = nil;
        [self autorelease];
    }
}

@end
