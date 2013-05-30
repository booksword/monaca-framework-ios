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

- (id)initWithViewController:(MFViewController *)viewController
{
    self = [super init];

    if (self) {
        _viewController = viewController;
        _navigationBar = viewController.navigationController.navigationBar;
        _centerViewToolbar = [[UIToolbar alloc] init];
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

    if (![[_titleView retrieveUIStyle:kNCStyleTitle] isEqualToString:TitleUndefined]) {
        _viewController.navigationItem.titleView = nil;
        _viewController.navigationItem.titleView = _titleView;
    } else {
        if ([visiableContainers count] > 2) {
            [_centerViewToolbar setItems:visiableContainers];
            // TODO: allow few containers
            _viewController.navigationItem.titleView = nil;
            _viewController.navigationItem.titleView = [[visiableContainers objectAtIndex:1] view];
        } else {
            _viewController.navigationItem.titleView = nil;
        }
    }
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

- (void)updateUIStyle:(id)value forKey:(NSString *)key
{
    if (![_ncStyle checkStyle:value forKey:key]) {
        return;
    }

    if ([key isEqualToString:kNCStyleVisibility]) {
        BOOL hidden = NO;
        if (isFalse(value)) {
            hidden = YES;
        }
        [_viewController.navigationController setNavigationBarHidden:hidden];
    }
    if ([key isEqualToString:kNCStyleBackgroundColor]) {
        [_navigationBar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
        [_centerViewToolbar setTintColor:hexToUIColor(removeSharpPrefix(value), 1)];
    }

    // title,subtitleに関してはNCTitleViewに委譲
    [_titleView updateUIStyle:value forKey:key];
    
    if ([key isEqualToString:kNCStyleIOSBarStyle]) {
        UIBarStyle style = UIBarStyleDefault;
        if ([value isEqualToString:kNCBarStyleBlack]) {
            style = UIBarStyleBlack;
            [_navigationBar setTranslucent:NO];
        } else if ([value isEqualToString:kNCBarStyleBlackOpaque]) {
            style = UIBarStyleBlackOpaque;
            [_navigationBar setTranslucent:NO];
        } else if ([value isEqualToString:kNCBarStyleBlackTranslucent]) {
            style = UIBarStyleBlackTranslucent;
            [_navigationBar setTranslucent:YES];
        } else if ([value isEqualToString:kNCBarStyleDefault]) {
            style = UIBarStyleDefault;
            [_navigationBar setTranslucent:NO];
        }
        [_navigationBar setBarStyle:style];
    }
    if ([key isEqualToString:kNCStyleShadowOpacity]) {
        CALayer *navBarLayer = _navigationBar.layer;
        //        navBarLayer.shadowColor = [[UIColor blackColor] CGColor];
        //        navBarLayer.shadowRadius = 3.0f;
        navBarLayer.shadowOffset = CGSizeMake(0.0f, 2.0f);

        [navBarLayer setShadowOpacity:[value floatValue]];
    }

    [_ncStyle updateStyle:value forKey:key];
}

- (id)retrieveUIStyle:(NSString *)key
{
    return [_ncStyle retrieveStyle:key];
}

@end
