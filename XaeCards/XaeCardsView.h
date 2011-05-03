/**
 @file XaeCardsView.h
 
 Created by Diego Garcia on 5/1/11.
 Copyright 2011 Diego Garcia. All rights reserved.
 */

#import <UIKit/UIKit.h>


@class XaeCardsView;
@protocol XaeCardsViewDataSource;
@protocol XaeCardsViewDelegate;

#pragma mark -
@interface XaeCardsView : UIView {
@private
  // Delegate and data source (trailing underscore messes up IB, somehow)
  id<XaeCardsViewDataSource> dataSource; // (weak)
  id<XaeCardsViewDelegate> delegate; // (weak)
  
  // Layout
  CGSize cardSize_; // Size of each card
  CGFloat cardSpacing_; // Space between the position of two cards
  NSUInteger sideCards_; // Extra cards on each side from the current one
  
  NSDictionary *((*layoutFunction_)(CGFloat, XaeCardsView*));
  
  // Card data
  NSUInteger cardCount_; // Number of cards in view (cached from datasource)
  NSMutableDictionary *cardImages_; // Array of cards CGImages (strong)
  NSMutableDictionary *cardLayers_; // Array of cards CALayers (strong)
  
  // State
  BOOL needsReload_;
  NSInteger currentPlacement_; // the card currently closest to the "center"
  NSInteger targetPlacement_; // the card we are animating to the "center"
  CGFloat displacement_; // displacement of cards from their "center"
  
  // Gesture recognizers (strong)
  UITapGestureRecognizer *tapRecognizer_;
  UIPanGestureRecognizer *panRecognizer_;
}
#pragma mark Properties
// The object that acts as the data source of the receiving card flow.
@property(nonatomic,assign) IBOutlet id<XaeCardsViewDataSource> dataSource;

// The object that acts as the delegate of the receiving card flow.
@property(nonatomic,assign) IBOutlet id<XaeCardsViewDelegate> delegate;


// The number of cards in the receiver.
@property(nonatomic,readonly) NSUInteger numberOfCards;

// The size of each card in the receiver.
@property(nonatomic,assign) CGSize cardSize;

// The size of each card in the receiver.
@property(nonatomic,assign) CGFloat cardSpacing;

// The number of cards to each side of the center card.
// e.g. if this property is two, there will be five cards in display
@property(nonatomic,assign) NSUInteger sideCards;


#pragma mark Instance methods

// Reloads the specified card
- (void)reloadCardAtIndex:(NSUInteger)index;

// Reloads the cards of the receiver.
- (void)reloadData;

// Set the layout function.  You can use one of the included functions or
// create your own.
- (void)setLayoutFunction:(NSDictionary*(*)(CGFloat, XaeCardsView*))func;

// Center the view on the card that is |interval| positions away from the
// current card.  A positive interval will center on a card to the right of the
// current.  A negative interval to the left.
- (void)centerOnCardAtInterval:(NSInteger)interval animated:(BOOL)animated;

@end


#pragma mark -
@protocol XaeCardsViewDataSource

// Asks the data source for a card to insert in a particular location of the
// view.  The view is not retained, and can be reused by the data source if.
//
// Parameters
//  cardFlow
//    The card flow object requesting the view.
//  index
//    A zero-indexed card position in |cardFlow|.
- (UIView*)cardFlow:(XaeCardsView*)cardFlow cardAtIndex:(NSUInteger)index;

// Tells the data source to return the number of card in a card flow.
//
// Parameters
//  cardFlow
//    The card flow object requesting the view.
- (NSUInteger)numberOfCardsInCardFlow:(XaeCardsView*)cardFlow;

@end


#pragma mark -
@protocol XaeCardsViewDelegate

@optional

// Tells the delegate that the specified card is now on front.
//
// Parameters
//  cardFlow
//    The card flow object informing the delegate.
//  index
//    A zero-indexed card position in |cardFlow|.
- (void)cardFlow:(XaeCardsView*)cardFlow centeredOnCardAtIndex:(NSUInteger)index;

// Tells the delegate that the specified card was tapped.
//
// Parameters
//  cardFlow
//    The card flow object informing the delegate.
//  index
//    A zero-indexed card position in |cardFlow|.
- (void)cardFlow:(XaeCardsView*)cardFlow tapOnCardAtIndex:(NSUInteger)index;


@end


#pragma mark -
#pragma mark Layout functions

NSDictionary *kXaeCardsViewCardDeckLayout(CGFloat, XaeCardsView*);
