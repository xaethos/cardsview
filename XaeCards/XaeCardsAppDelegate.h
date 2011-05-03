//
//  XaeCardsAppDelegate.h
//  XaeCards
//
//  Created by Diego Garcia on 4/29/11.
//  Copyright 2011 Maven Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XaeCardsViewController;

@interface XaeCardsAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet XaeCardsViewController *viewController;

@end
