//
//  NCNavigationBar.m
//  MonacaFramework
//
//  Created by Yasuhiro Mitsuno on 2013/04/28.
//  Copyright (c) 2013年 ASIAL CORPORATION. All rights reserved.
//

#import "NCNavigationBar.h"
#import "MFUtility.h"

#import <QuartzCore/QuartzCore.h>

@implementation NCNavigationBar

@synthesize viewController = _viewController;
@synthesize type = _type;

- (id)initWithViewController:(MFViewController *)viewController
{
    self = [super init];

    if (self) {
        _viewController = viewController;
        _type = kNCContainerToolbar;
        _navigationBar = viewController.navigationController.navigationBar;
        _centerView = nil;
        _titleView = [[NCTitleView alloc] init];
        _ncStyle = [[NCStyle alloc] initWithComponent:kNCContainerToolbar];
    }

    return self;
}

- (void)createNavigationBar:(NSDictionary *)uidict
{
    NSArray *topRight = [uidict objectForKey:kNCTypeRight];
    NSArray *topLeft = [uidict objectForKey:kNCTypeLeft];
    NSArray *topCenter = [uidict objectForKey:kNCTypeCenter];

    NSMutableDictionary *style = [NSMutableDictionary dictionary];
    [style addEntriesFromDictionary:[uidict objectForKey:kNCTypeStyle]];
    [style addEntriesFromDictionary:[uidict objectForKey:kNCTypeIOSStyle]];
    
    if (uidict != nil) {
        [_viewController.navigationController setNavigationBarHidden:NO];
    }

    [self setUserInterface:style];
    [self applyUserInterface];

    /***** create leftContainers *****/
    NSMutableArray *containers = [NSMutableArray array];
    for (id component in topLeft) {
        NCContainer *container = [NCContainer container:component forToolbar:self];
        if (container.component == nil) continue;
        if ([container.type isEqualToString:kNCComponentBackButton]) {
            if (_backButton == nil) {
                _backButton = container;
            } else {
                continue;
            }
        }
        [containers addObject:container.component];
        [_viewController.ncManager setComponent:container forID:container.cid];
    }
    _leftContainers = containers;
    [_viewController setBackButton:_backButton];

    /***** create rightContainers *****/
    containers = [NSMutableArray array];
    for (id component in topRight) {
        NCContainer *container = [NCContainer container:component forToolbar:self];
        if (container.component == nil) continue;
        if ([container.type isEqualToString:kNCComponentBackButton]) continue;
        [containers addObject:container.component];
        [_viewController.ncManager setComponent:container forID:container.cid];
    }
    // 表示順序を入れ替える
    NSMutableArray *reverseContainers = [NSMutableArray array];
    while ([containers count] != 0){
        [reverseContainers addObject:[containers lastObject]];
        [containers removeLastObject];
    }
    _rightContainers = reverseContainers;

    /***** create centerContainers *****/
    containers = [NSMutableArray array];
    for (id component in topCenter) {
        NCContainer *container = [NCContainer container:component forToolbar:self];
        if (container.component == nil) continue;
        [containers addObject:container.component];
        [_viewController.ncManager setComponent:container forID:container.cid];
    }
    _centerContainers = containers;

  [self applyVisibility];
}

- (void)applyBackButton
{
    if (_backButton) {
        NSArray *viewControllers = [_viewController.navigationController viewControllers];
        if ([viewControllers count]> 1) {
            [[[viewControllers objectAtIndex:[viewControllers count]-2] navigationItem] setBackBarButtonItem:nil];
            [[[viewControllers objectAtIndex:[viewControllers count]-2] navigationItem] setBackBarButtonItem:_backButton.component];
            [_viewController.navigationItem setHidesBackButton:[_backButton.component hidden] animated:YES];
            [_viewController.navigationItem setLeftItemsSupplementBackButton:YES];
        }
    } else {
        [_viewController.navigationItem setHidesBackButton:YES];
    }
}

- (void)applyVisibility
{
    /***** apply leftContainers *****/
    NSMutableArray *visiableContainers = [NSMutableArray array];
    for (NCBarButtonItem *container in _leftContainers) {
        if (![container hidden] && ![container isKindOfClass:[NCBackButton class]]) {
            [visiableContainers addObject:container];
        }
    }
    _viewController.navigationItem.leftBarButtonItems = visiableContainers;

    /***** apply backButton Container *****/
    [self applyBackButton];

    /***** apply rightContainers *****/
    visiableContainers = [NSMutableArray array];
    for (NCBarButtonItem *container in _rightContainers) {
        if (![container hidden]) {
            [visiableContainers addObject:container];
        }
    }
    _viewController.navigationItem.rightBarButtonItems = visiableContainers;

    /***** apply centerContainers *****/
    UIBarButtonItem *spacer =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    visiableContainers = [NSMutableArray array];

    [visiableContainers addObject:spacer];
    for (NCBarButtonItem *container in _centerContainers) {
        if (![container hidden]) {
            [visiableContainers addObject:container];
        }
    }
    [visiableContainers addObject:spacer];

    if ([visiableContainers count] > 2) {
        // TODO: allow few containers
        _centerView = [[visiableContainers objectAtIndex:1] view];
    }
    
    [self applyTitleViewVisibility];
}

- (void)applyTitleViewVisibility
{
    if ([[_titleView retrieveUIStyle:kNCStyleTitle] isEqualToString:kNCUndefined] &&
        [[_titleView retrieveUIStyle:kNCStyleSubtitle] isEqualToString:kNCUndefined] &&
        [[_titleView retrieveUIStyle:kNCStyleTitleImage] isEqualToString:kNCUndefined]) {
        _viewController.navigationItem.titleView = nil;
        _viewController.navigationItem.titleView = _centerView;
    } else {
        _viewController.navigationItem.titleView = nil;
        _viewController.navigationItem.titleView = _titleView;
    }
}

- (void)setBackgroundColor:(id)value
{

#ifdef XCODE5
    if ([MFDevice iOSVersionMajor] <= 6) {
        [_navigationBar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    } else {
        // iOS7以降でbarTintColorを変更する
    #ifdef __IPHONE_7_0
        [_navigationBar setBarTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    #endif
    }
    
#else
    [_navigationBar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
#endif

}

- (void)setOpacity:(id)value
{
#ifdef XCODE5
    // iOS7では対応しない
    if ([MFDevice iOSVersionMajor] <= 6) {
        [[[_navigationBar subviews] objectAtIndex:0] setAlpha:[value floatValue]];
    }
#else
        [[[_navigationBar subviews] objectAtIndex:0] setAlpha:[value floatValue]];
#endif
}

- (void)setShadowOpacity:(id)value
{
#ifdef XCODE5
    // iOS7では対応しない
    if ([MFDevice iOSVersionMajor] <= 6) {
        CALayer *navBarLayer = _navigationBar.layer;
        //        navBarLayer.shadowColor = [[UIColor blackColor] CGColor];
        //        navBarLayer.shadowRadius = 3.0f;
        navBarLayer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
        [navBarLayer setShadowOpacity:[value floatValue]];
    }
#else
    CALayer *navBarLayer = _navigationBar.layer;
    //        navBarLayer.shadowColor = [[UIColor blackColor] CGColor];
    //        navBarLayer.shadowRadius = 3.0f;
    navBarLayer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
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
        [_navigationBar setTranslucent:translucent];
    }
#endif
}
    
- (void)setIosThemeColor:(id)value
{
#ifdef XCODE5
    // iOS7のみ
    if ([MFDevice iOSVersionMajor] >= 7) {
        [_navigationBar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
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
    [self applyBackButton];
}
    

- (void)removeUserInterface
{
    _viewController.navigationItem.leftBarButtonItems = nil;
    _viewController.navigationItem.rightBarButtonItems = nil;
    _viewController.navigationItem.titleView = nil;
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
        [_viewController.navigationController setNavigationBarHidden:hidden];
    }
    if ([key isEqualToString:kNCStyleBackgroundColor]) {
        if (_navigationBar.barStyle == UIBarStyleDefault) {
            [self setBackgroundColor:value];
        }
    }
    
#ifdef XCODE5
    if ([key isEqualToString:kNCStyleOpacity] && [MFDevice iOSVersionMajor] <= 6) {
        if (_navigationBar.barStyle == UIBarStyleDefault) {
            [self setOpacity:value];
            if ([value floatValue] == 1.0) {
                [_navigationBar setTranslucent:NO];
                
                [self updateUIStyle:[self retrieveUIStyle:kNCStyleIOSBarStyle] forKey:kNCStyleIOSBarStyle];
            } else {
                [_navigationBar setTranslucent:YES];
            }
        }
    }
#else
    if ([key isEqualToString:kNCStyleOpacity]) {
        if (_navigationBar.barStyle == UIBarStyleDefault) {
            [self setOpacity:value];
            if ([value floatValue] == 1.0) {
                [_navigationBar setTranslucent:NO];
                
                [self updateUIStyle:[self retrieveUIStyle:kNCStyleIOSBarStyle] forKey:kNCStyleIOSBarStyle];
            } else {
                [_navigationBar setTranslucent:YES];
            }
        }
    }
#endif

    // title,subtitleに関してはNCTitleViewに委譲
    [_titleView updateUIStyle:value forKey:key];
    if ([key isEqualToString:kNCStyleTitle] || [key isEqualToString:kNCStyleSubtitle]) {
        [self applyTitleViewVisibility];
    }
    
    if ([key isEqualToString:kNCStyleIOSBarStyle]) {
        UIBarStyle style = UIBarStyleDefault;
        if ([value isEqualToString:kNCBarStyleBlack]) {
            style = UIBarStyleBlack;
            
            [_navigationBar setTranslucent:NO];
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
            [_navigationBar setTranslucent:NO];
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
            [_navigationBar setTranslucent:YES];
        } else if ([value isEqualToString:kNCBarStyleDefault]) {
            style = UIBarStyleDefault;
            
            [_navigationBar setTranslucent:NO];
        }
        
        if (style == UIBarStyleDefault) {
            [self setBackgroundColor:[self retrieveUIStyle:kNCStyleBackgroundColor]];
            [self setOpacity:[self retrieveUIStyle:kNCStyleOpacity]];
            [self setShadowOpacity:[self retrieveUIStyle:kNCStyleShadowOpacity]];
        } else {
            [_navigationBar setTintColor:nil];
            [self setOpacity:[_ncStyle getDefaultStyle:kNCStyleOpacity]];
            [self setShadowOpacity:[_ncStyle getDefaultStyle:kNCStyleShadowOpacity]];
        }
        
        [_navigationBar setBarStyle:style];
        
        // デフォルトのtranslucentとthemeColorの値を書き換える
        if ([MFDevice iOSVersionMajor] >= 7) {
            [self setTranslucent:[self retrieveUIStyle:kNCStyleTranslucent]];
            [self setIosThemeColor:[self retrieveUIStyle:kNCStyleIosThemeColor]];
        }
    }
    if ([key isEqualToString:kNCStyleShadowOpacity] && [MFDevice iOSVersionMajor] <= 6) {
        if (_navigationBar.barStyle == UIBarStyleDefault) {
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
