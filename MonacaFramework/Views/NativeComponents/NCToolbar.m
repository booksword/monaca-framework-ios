//
//  NCToolbar.m
//  MonacaFramework
//
//  Created by Nakagawa Hiroki on 12/02/15.
//  Copyright (c) 2012年 ASIAL CORPORATION. All rights reserved.
//

#import "NCToolbar.h"
#import "MFUtility.h"
#import "NCBarButtonItem.h"

#import <QuartzCore/QuartzCore.h>

@implementation NCToolbar

@synthesize viewController = _viewController;
@synthesize type = _type;

- (id)initWithViewController:(MFViewController *)viewController
{
    self = [super init];
    
    if (self) {
        _viewController = viewController;
        _type = kNCContainerToolbar;
        _toolbar = viewController.navigationController.toolbar;
        _ncStyle = [[NCStyle alloc] initWithComponent:kNCContainerToolbar];
    }

    return self;
}

- (void)createToolbar:(NSDictionary *)uidict
{
    NSArray *topRight = [uidict objectForKey:kNCTypeRight];
    NSArray *topLeft = [uidict objectForKey:kNCTypeLeft];
    NSArray *topCenter = [uidict objectForKey:kNCTypeCenter];

    NSMutableDictionary *style = [NSMutableDictionary dictionary];
    [style addEntriesFromDictionary:[uidict objectForKey:kNCTypeStyle]];
    [style addEntriesFromDictionary:[uidict objectForKey:kNCTypeIOSStyle]];
    
    if (uidict != nil) {
        [_viewController.navigationController setToolbarHidden:NO];
    }

    [self setUserInterface:style];
    [self applyUserInterface];
    
    UIBarButtonItem *spacer =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *negativeSpacer =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = -7.0f;
    
    /***** create leftContainers *****/
    NSMutableArray *containers = [NSMutableArray array];
    if (topLeft) {
        [containers addObject:negativeSpacer];
        for (id component in topLeft) {
            NCContainer *container = [NCContainer container:component forToolbar:self];
            if (container.component == nil) continue;
            [containers addObject:container.component];
            [_viewController.ncManager setComponent:container forID:container.cid];
        }
    }

    /***** create centerContainers *****/
    [containers addObject:spacer];
    if (topCenter) {
        for (id component in topCenter) {
            NCContainer *container = [NCContainer container:component forToolbar:self];
            if (container.component == nil) continue;
            [containers addObject:container.component];
            [_viewController.ncManager setComponent:container forID:container.cid];
        }
    }
    [containers addObject:spacer];
    /***** create rightContainers *****/
    if (topRight) {
        for (id component in topRight) {
            NCContainer *container = [NCContainer container:component forToolbar:self];
            if (container.component == nil) continue;
            [containers addObject:container.component];
            [_viewController.ncManager setComponent:container forID:container.cid];
        }
        // 右のスペースをnavigationBarのそれと合わせる
        [containers addObject:negativeSpacer];
    }
    
    _containers = containers;
    [self applyVisibility];
}

- (void)applyVisibility
{
    NSMutableArray *visiableContainers = [NSMutableArray array];
    for (id container in _containers) {
        if ([container isKindOfClass:[NCBarButtonItem class]]) {
            if (![container hidden]) {
                [visiableContainers addObject:container];
            }
        } else {
            [visiableContainers addObject:container];
        }
    }
    [_viewController setToolbarItems:visiableContainers];
}

- (void)setBackgroundColor:(id)value
{
#ifdef XCODE5
    if ([MFDevice iOSVersionMajor] <= 6) {
        [_toolbar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    } else {

        // iOS7以降でbarTintColorを変更する
    #ifdef __IPHONE_7_0
        [_toolbar setBarTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    #endif
    }
#else
        [_toolbar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
#endif
}

- (void)setOpacity:(id)value
{
#ifdef XCODE5
    if ([MFDevice iOSVersionMajor] <= 6) {
        [[[_toolbar subviews] objectAtIndex:0] setAlpha:[value floatValue]];
        if ([MFDevice iOSVersionMajor] >= 6) {
            // iOS6以降では枠が別に用意されている．
            [[[_toolbar subviews] objectAtIndex:1] setAlpha:[value floatValue]];
        }
    }
#else
    [[[_toolbar subviews] objectAtIndex:0] setAlpha:[value floatValue]];
#endif
}

- (void)setShadowOpacity:(id)value
{
#ifdef XCODE5
    if ([MFDevice iOSVersionMajor] <= 6) {
        CALayer *navBarLayer = _toolbar.layer;
        //        navBarLayer.shadowColor = [[UIColor blackColor] CGColor];
        //        navBarLayer.shadowRadius = 3.0f;
        navBarLayer.shadowOffset = CGSizeMake(0.0f, -2.0f);
    
        [navBarLayer setShadowOpacity:[value floatValue]];
    }
#else
    CALayer *navBarLayer = _toolbar.layer;
    //        navBarLayer.shadowColor = [[UIColor blackColor] CGColor];
    //        navBarLayer.shadowRadius = 3.0f;
    navBarLayer.shadowOffset = CGSizeMake(0.0f, -2.0f);
    [navBarLayer setShadowOpacity:[value floatValue]];
#endif
}


- (void)setTranslucent:(id)value
{
#ifdef XCODE5
    // iOS7のみ
    if ([MFDevice iOSVersionMajor] >= 7) {
        BOOL translucent = NO;
        if (isTrue(value)) {
            translucent = YES;
        }
        [_toolbar setTranslucent:translucent];
    }
#endif
}

- (void)setIosThemeColor:(id)value
{
#ifdef XCODE5
    // iOS7のみ
    if ([MFDevice iOSVersionMajor] >= 7) {
        [_toolbar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    }
#endif
}

#pragma mark - UIStyleProtocol

- (void)setUserInterface:(NSDictionary *)uidict
{
    [_ncStyle setStyles:uidict];
}

- (void)applyUserInterface
{
    for (id key in [_ncStyle styles]) {
        [self updateUIStyle:[[_ncStyle styles] objectForKey:key] forKey:key];
    }
}


- (void)removeUserInterface
{
    _viewController.toolbarItems = nil;
}

- (void)updateUIStyle:(id)value forKey:(NSString *)key
{
    if (![_ncStyle checkStyle:value forKey:key]) {
        return;
    }

    if (value == [NSNull null]) {
        value = kNCUndefined;
    }
    if ([NSStringFromClass([[_ncStyle.styles valueForKey:key] class]) isEqualToString:@"__NSCFBoolean"]) {
        if (isFalse(value)) {
            value = kNCFalse;
        } else {
            value = kNCTrue;
        }
    }
    
    if ([key isEqualToString:kNCStyleVisibility]) {
        BOOL hidden = NO;
        if (isFalse(value)) {
            hidden = YES;
        }
        [_viewController.navigationController setToolbarHidden:hidden];
    }
    if ([key isEqualToString:kNCStyleBackgroundColor]) {
        if (_toolbar.barStyle == UIBarStyleDefault) {
            [self setBackgroundColor:value];
        }
    }
    if ([key isEqualToString:kNCStyleOpacity] && [MFDevice iOSVersionMajor] <= 6) {
        if (_toolbar.barStyle == UIBarStyleDefault) {
            [self setOpacity:value];
            if ([value floatValue] >= 1.0) {
                [_toolbar setTranslucent:NO];
            } else {
                [_toolbar setTranslucent:YES];
            }
        }
    }
    if ([key isEqualToString:kNCStyleIOSBarStyle]) {
        UIBarStyle style = UIBarStyleDefault;
        if ([value isEqualToString:kNCBarStyleBlack]) {
            style = UIBarStyleBlack;
            [_toolbar setTranslucent:NO];
        } else if ([value isEqualToString:kNCBarStyleBlackOpaque]) {
#ifdef XCODE5
            // iOS7ではUIBarStyleBlackOpaqueはdeprecated
            if ([MFDevice iOSVersionMajor] <= 6) {
                style = UIBarStyleBlackOpaque;
            } else {
                style = UIBarStyleBlack;
            }
#else
                style = UIBarStyleBlackOpaque;
#endif
            [_toolbar setTranslucent:NO];
        } else if ([value isEqualToString:kNCBarStyleBlackTranslucent]) {
#ifdef XCODE5
            // iOS7ではUIBarStyleBlackTranslucentはdeprecated
            if ([MFDevice iOSVersionMajor] <= 6) {
                style = UIBarStyleBlackTranslucent;
            } else {
                style = UIBarStyleBlack;
            }
#else
                style = UIBarStyleBlackTranslucent;
#endif
            [_toolbar setTranslucent:YES];
        } else if ([value isEqualToString:kNCBarStyleDefault]) {
            style = UIBarStyleDefault;
            
            [_toolbar setTranslucent:NO];
        }

        if (style == UIBarStyleDefault) {
            [self setBackgroundColor:[self retrieveUIStyle:kNCStyleBackgroundColor]];
            [self setOpacity:[self retrieveUIStyle:kNCStyleOpacity]];
            [self updateUIStyle:[self retrieveUIStyle:kNCStyleShadowOpacity] forKey:kNCStyleShadowOpacity];
        } else {
            [_toolbar setTintColor:nil];
            [self setOpacity:[_ncStyle getDefaultStyle:kNCStyleOpacity]];
            [self setShadowOpacity:[_ncStyle getDefaultStyle:kNCStyleShadowOpacity]];
        }
        
        [_toolbar setBarStyle:style];
        
        // デフォルトのtranslucentとthemeColorの値を書き換える
        if ([MFDevice iOSVersionMajor] >= 7) {
            [self setTranslucent:[self retrieveUIStyle:kNCStyleTranslucent]];
            [self setIosThemeColor:[self retrieveUIStyle:kNCStyleIosThemeColor]];
        }
        
        [_viewController.navigationController setToolbarHidden:YES];
        if (!isFalse([self retrieveUIStyle:kNCStyleVisibility])) {
            [_viewController.navigationController setToolbarHidden:NO];
        }        
    }
    if ([key isEqualToString:kNCStyleShadowOpacity] && [MFDevice iOSVersionMajor] <= 6) {
        if (_toolbar.barStyle == UIBarStyleDefault) {
            if ([value floatValue] < 0.0f) {
                value = [NSNumber numberWithFloat:0.0f];
            } if ([value floatValue] > 1.0f) {
                value = [NSNumber numberWithFloat:1.0f];
            }
            [self setShadowOpacity:value];
        }
    }
    if ([key isEqualToString:kNCStyleTranslucent] && [MFDevice iOSVersionMajor] >= 7) {
        [self setTranslucent:value];
    }
    
    if ([key isEqualToString:kNCStyleIosThemeColor] && [MFDevice iOSVersionMajor] >= 7) {
        [self setIosThemeColor:value];
    }

    [_ncStyle updateStyle:value forKey:key];
}

- (id)retrieveUIStyle:(NSString *)key
{
    return [_ncStyle retrieveStyle:key];
}

@end
