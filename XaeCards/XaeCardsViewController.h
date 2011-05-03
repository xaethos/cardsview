//
//  XaeCardsViewController.h
//  XaeCards
//
//  Created by Diego Garcia on 4/29/11.
//  Copyright 2011 Maven Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XaeCardsView.h"


@interface XaeCardsViewController : UIViewController<
XaeCardsViewDataSource,
XaeCardsViewDelegate
> {
 @private
  // IB Outlets
  XaeCardsView *cardsView_;
}
@property(nonatomic,retain) IBOutlet XaeCardsView *cardsView;

@end
