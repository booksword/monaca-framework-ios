//
//  MonacaViewController.h
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDVViewController.h"
#import "NCManager.h"
#import "NCContainer.h"
#import "UIStyleProtocol.h"

@interface MFViewController : CDVViewController <UIScrollViewDelegate, UIWebViewDelegate>
{
@private
    NSString *_previousPath;
    NCManager *_ncManager_;
    NSDictionary *_uiDict;
    id<UIStyleProtocol> _navigationBar;
    id<UIStyleProtocol> _toolbar;
    NCContainer *_backButton;
}
- (void)setUserInterface:(NSDictionary *)uidict;
- (void)applyUserInterface;
- (void)sendPush;
- (id)initWithFileName:(NSString *)fileName;
- (void)destroy;
- (void)showSplash:(BOOL)show;

@property (nonatomic, copy) NSString *previousPath;
@property (nonatomic, retain) NCManager *ncManager;
@property (nonatomic, retain) NSDictionary *uiDict;
@property (nonatomic, retain) NSDictionary *monacaPluginOptions;
@property (nonatomic, retain) NCContainer *backButton;


@end
