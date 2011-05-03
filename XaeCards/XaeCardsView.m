/**
 @file XaeCardsView.m
 
 Created by Diego Garcia on 5/1/11.
 Copyright 2011 Diego Garcia. All rights reserved.
 */

#import "XaeCardsView.h"

#import <QuartzCore/QuartzCore.h>

#pragma mark Constants

// Default layout
#define kCardWidthDefault 200.0f
#define kCardHeightDefault 250.0f

// Special keys for layers
static NSString *kCardKeyPlacement = @"net.xaethos.CardsViewPlacement";
static NSString *kCardKeyDisplacement = @"net.xaethos.CardsViewDisplacement";

// Macros
#define rangeIncludesIndex(r, i) \
((r).location <= (i) && ((r).location+(r).length) >= (i))

#define cardFlowDuration(t, p) (0.7f / (1.0f + abs((t)-(p))))



#pragma mark -
@interface XaeCardsView()

@property(nonatomic,assign) NSInteger currentPlacement;

- (void)setCardCount:(NSUInteger)count;

// Layout
- (void)layoutCard:(CALayer*)cardLayer animated:(BOOL)animated;
- (void)layoutCardsOnDisplay:(BOOL)animated;

// Data
- (void)setLayer:(CALayer*)layer forPlacement:(NSInteger)placement;
- (void)unsetLayerForPlacement:(NSInteger)placement;
- (CALayer*)layerForPlacement:(NSInteger)placement;

- (void)setImage:(CGImageRef)image forCardAtIndex:(NSUInteger)index;
- (void)unsetImageForCardAtIndex:(NSUInteger)index;
- (CGImageRef)imageForCardAtIndex:(NSUInteger)index;

// Gestures
- (void)handleTapGesture;
- (void)handlePanGesture;

// Utilities
- (NSRange)rangeForPlacement:(NSInteger)placement;
- (NSUInteger)indexOfCardAtPlacement:(NSInteger)placement;

@end


#pragma mark -
@implementation XaeCardsView

#pragma mark Class methods

+ (CGImageRef)imageForView:(UIView*)view {
  CALayer *layer = view.layer;
  
  // Get a UIImage from the view's contents.
  // Gotta do some version juggling for this.
  if (&UIGraphicsBeginImageContextWithOptions != NULL) {
    // iOS 4.0 and up
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
  }
  else {
    // iOS 3.2 and under
    UIGraphicsBeginImageContext(view.frame.size);
  }
  
  [layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  // Convert UIImage to CGImage
  return image.CGImage;
}

+ (CATransform3D)transformForDisplacement:(CGFloat)displacement
                                  spacing:(CGFloat)spacing {
  CATransform3D t = CATransform3DIdentity;
  
  CGFloat z = -1-fabs(displacement);
  
  if (displacement > spacing) displacement = spacing;
  else if (displacement < -spacing) displacement = -spacing;
  
  CGFloat x = spacing * atan(4*displacement/spacing) / M_PI_2;
  CGFloat y = -(displacement*displacement)/1000;
  
  CGFloat rotation = -(displacement/spacing) * M_PI_4;
  
  t = CATransform3DTranslate(t, x, y, z);
  t = CATransform3DRotate(t, rotation, 0, 0, 1);
  
  return t;
}

#pragma mark Properties

@dynamic dataSource;
@dynamic delegate;

@synthesize numberOfCards = cardCount_;
@synthesize cardSize = cardSize_;
@synthesize cardSpacing = cardSpacing_;
@synthesize sideCards = sideCards_;

@dynamic currentPlacement;

- (id<XaeCardsViewDataSource>)dataSource { return dataSource; }
- (void)setDataSource:(id<XaeCardsViewDataSource>)newSource {
  dataSource = newSource;
  needsReload_ = YES;
}

- (id<XaeCardsViewDelegate>)delegate { return delegate; }
- (void)setDelegate:(id<XaeCardsViewDelegate>)newDelegate {
  delegate = newDelegate;
  
  // Add/remove tap handler depending on delegate support
  if ([(id)delegate respondsToSelector:@selector(cardFlow:tapOnCardAtIndex:)]) {
    if (!tapRecognizer_.view) {
      [self addGestureRecognizer:tapRecognizer_];
    }
  }
  else if (tapRecognizer_.view) {
    [self removeGestureRecognizer:tapRecognizer_];
  }
}

- (void)setLayoutFunction:(NSDictionary*(*)(CGFloat, XaeCardsView*))func {
  layoutFunction_ = func;
}

- (void)setCardCount:(NSUInteger)count {
  cardCount_ = count;
  
  // If no cards are available, disable touches
  if (count == 0) {
    tapRecognizer_.enabled = NO;
    panRecognizer_.enabled = NO;
  }
  else {
    tapRecognizer_.enabled = YES;
    panRecognizer_.enabled = YES;
  }
  
}

- (NSInteger)currentPlacement { return currentPlacement_; }
- (void)setCurrentPlacement:(NSInteger)newPlacement {
  currentPlacement_ = newPlacement;
  
  // Unload the unecessary layers
  NSRange keep = [self rangeForPlacement:currentPlacement_];
  NSInteger cardPlacement;
  
  for (NSNumber *key in [cardLayers_ allKeys]) {
    cardPlacement = [key integerValue];
    if (!rangeIncludesIndex(keep, cardPlacement)) {
      [self unsetLayerForPlacement:cardPlacement];
    }
  }
}

- (void)setFrame:(CGRect)rect {
  [super setFrame:rect];
  
  [self reloadData];
}

#pragma mark View lifecycle

- (void)commonInitialization {
  // Card flow configuration
  cardSize_ = CGSizeMake(kCardWidthDefault, kCardHeightDefault);
  cardSpacing_ = kCardWidthDefault * 1.15;
  sideCards_ = 1;
  
  layoutFunction_ = &kXaeCardsViewCardDeckLayout;
  
  needsReload_ = YES;
  
  cardImages_ = [[NSMutableDictionary alloc] init];
  cardLayers_ = [[NSMutableDictionary alloc] init];
  
  // Gesture recognizers
  tapRecognizer_ =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleTapGesture)];
  [self addGestureRecognizer:tapRecognizer_];
  
  panRecognizer_ =
  [[UIPanGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handlePanGesture)];
  [self addGestureRecognizer:panRecognizer_];
}

// Designated initializer
- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    [self commonInitialization];
  }
  return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
  if ((self = [super initWithCoder:aDecoder])) {
    [self commonInitialization];
  }
  return self;
}

- (void)dealloc {
  [cardImages_ release];
  [cardLayers_ release];
  
  [tapRecognizer_ release];
  [panRecognizer_ release];
  
  [super dealloc];
}


#pragma mark UIView overrides

- (void)layoutSubviews {
  if (needsReload_) [self reloadData];
  
  [super layoutSubviews];
}


#pragma mark Animation

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
  if (flag && targetPlacement_ != currentPlacement_) {
    if (targetPlacement_ > currentPlacement_) {
      self.currentPlacement += 1;
    }
    else {
      self.currentPlacement -= 1;
    }
    
    [self layoutCardsOnDisplay:YES];
  }
}


#pragma mark Layout

- (void)layoutCard:(CALayer*)cardLayer animated:(BOOL)animated {
  // Get the card's placement and displacement from the view center.
  NSInteger placement = [[cardLayer valueForKey:kCardKeyPlacement] integerValue];
  NSInteger placementOffset = placement - self.currentPlacement;
  CGFloat displacement = displacement_ + placementOffset;

  CABasicAnimation *animation;
  
  // Get the layer configuration for the card displacement
  NSDictionary *valuesDict = layoutFunction_(displacement, self);
  
  // Set the values, overriding any implicit animation
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  for (NSString *key in valuesDict) {
    id newValue = [valuesDict valueForKey:key];
    
    // Create an animation if requested
    if (animated) {
      animation = [CABasicAnimation animationWithKeyPath:key];
      animation.fromValue = [cardLayer valueForKey:key];
      animation.toValue = newValue;
      animation.duration = cardFlowDuration(targetPlacement_,
                                            currentPlacement_);
      
      if (placement == currentPlacement_) {
        animation.delegate = self;
      }
      
      [cardLayer addAnimation:animation
                       forKey:[NSString stringWithFormat:@"%@%d", key, placement]];
    }
    
    [cardLayer setValue:newValue forKey:key];
  }
  
  [CATransaction commit];
}

- (void)layoutCardsOnDisplay:(BOOL)animated {
  NSRange range = [self rangeForPlacement:currentPlacement_];
  
  for (NSInteger i=0; i<range.length; ++i) {
    [self layoutCard:[self layerForPlacement:(range.location + i)]
            animated:animated];
  }
}


#pragma mark Flowing

- (void)centerOnCardAtInterval:(NSInteger)interval animated:(BOOL)animated {
  displacement_ = 0.0f;
  
  if (!animated) {
    // Then this becomes dead simple
    self.currentPlacement += interval;
    [self layoutCardsOnDisplay:NO];
  }
  
  // Figure out where we're animating to
  targetPlacement_ = currentPlacement_ + interval;
  
  if (targetPlacement_ > currentPlacement_) {
    self.currentPlacement += 1;
  }
  else if (targetPlacement_ < currentPlacement_) {
    self.currentPlacement -= 1;
  }
  
  [self layoutCardsOnDisplay:YES];
}


#pragma mark Data

//TODO: check this function.  Something feels weird about it.
- (void)setLayer:(CALayer*)subLayer forPlacement:(NSInteger)placement {
  // Unset previous layer, just in case
  [self unsetLayerForPlacement:placement];
  
  // Now... just add the new layer
  [cardLayers_ setObject:subLayer
                  forKey:[NSNumber numberWithInteger:placement]];
}

- (void)unsetLayerForPlacement:(NSInteger)placement {
  NSNumber *key = [NSNumber numberWithInteger:placement];
  CALayer *subLayer = (CALayer*)[cardLayers_ objectForKey:key];
  
  if (subLayer) {
    [subLayer removeFromSuperlayer];
    [cardLayers_ removeObjectForKey:key];
  }
}

- (CALayer*)layerForPlacement:(NSInteger)placement {
  // First, check if the layer is already cached
  NSNumber *key = [NSNumber numberWithInteger:placement];
  CALayer *subLayer = [cardLayers_ objectForKey:key];
  
  if (!subLayer) {
    // We don't have this layer yet.  Let's create it.
    // Get the image for the card that goes in this placement
    NSUInteger index = [self indexOfCardAtPlacement:placement];
    CGImageRef image = [self imageForCardAtIndex:index];
    
    // Instantiate and setup layer object
    subLayer = [[[CALayer alloc] init] autorelease];
    subLayer.frame = CGRectMake(0, 0, cardSize_.width, cardSize_.height);
    subLayer.position = CGPointZero;
    subLayer.contents = (id)image;
    
    // Set values for our private properties
    [subLayer setValue:key forKey:kCardKeyPlacement];
    
    // Lay it out
    [self layoutCard:subLayer animated:NO];
    
    // It's a wrap!
    [self setLayer:subLayer forPlacement:placement];
    [self.layer addSublayer:subLayer];
  }
  
  return subLayer;
}

- (void)setImage:(CGImageRef)image forCardAtIndex:(NSUInteger)index {
  // Unset previous image first
  [self unsetImageForCardAtIndex:index];
  
  // Now we know |cardImages_| has no object for |index|
  CGImageRetain(image);
  [cardImages_ setObject:[NSValue valueWithPointer:image]
                  forKey:[NSNumber numberWithUnsignedInteger:index]];
}

- (void)unsetImageForCardAtIndex:(NSUInteger)index {
  NSNumber *key = [NSNumber numberWithUnsignedInteger:index];
  NSValue *imageValue = (NSValue*)[cardImages_ objectForKey:key];
  
  if (imageValue) {
    CGImageRef image;
    [imageValue getValue:&image];
    CGImageRelease(image);
    
    [cardImages_ removeObjectForKey:key];
  }
}

- (CGImageRef)imageForCardAtIndex:(NSUInteger)index {
  // First, check if the image is already cached
  NSNumber *key = [NSNumber numberWithUnsignedInteger:index];
  NSValue *imageValue = [cardImages_ objectForKey:key];
  CGImageRef image = NULL;
  
  if (!imageValue) {
    // We don't have this image yet.  Let's create it;
    // Get a card view from our datasource and generate the image from it.
    UIView *cardView = [dataSource cardFlow:self cardAtIndex:index];
    cardView.frame = CGRectMake(0, 0, cardSize_.width, cardSize_.height);
    image = [XaeCardsView imageForView:cardView];
    
    [self setImage:image forCardAtIndex:index];
  }
  else {
    [imageValue getValue:&image];
  }
  
  return image;
}

- (void)reloadCardAtIndex:(NSUInteger)index {
  // Reload the cached image
  [self unsetImageForCardAtIndex:index];
  CGImageRef newImage = [self imageForCardAtIndex:index];
  
  // Set the new content using implicit animation
  for (NSNumber *key in [cardLayers_ allKeys]) {
    if ([self indexOfCardAtPlacement:[key integerValue]] == index) {
      [(CALayer*)[cardLayers_ objectForKey:key] setContents:(id)newImage];
    }
  }
}

- (void)reloadData {
  needsReload_ = NO;
  if (!dataSource) return;
  
  // Release all card data
  for (NSNumber *placement in [cardLayers_ allKeys]) {
    [self unsetLayerForPlacement:[placement integerValue]];
  }
  
  for (NSNumber *index in [cardImages_ allKeys]) {
    [self unsetImageForCardAtIndex:[index unsignedIntegerValue]];
  }
  
  [self setCardCount:[dataSource numberOfCardsInCardFlow:self]];
  [self layoutCardsOnDisplay:NO];
}


#pragma mark Gestures

- (void)handleTapGesture {
  // Recognizer only enabled if the delegate handles taps, so no need to check.
  // Figure out which card was tapped, if any.
  CALayer *hitLayer = [self.layer hitTest:[tapRecognizer_ locationInView:self]];
  if (hitLayer && hitLayer != self.layer) {
    // Some layer was hit, and it wasn't us
    NSNumber *key = [[cardLayers_ allKeysForObject:hitLayer] lastObject];
    if (key) {
      [delegate cardFlow:self
        tapOnCardAtIndex:[self indexOfCardAtPlacement:[key integerValue]]];
    }
  }
}

- (void)handlePanGesture {
  // New gesture?
  if (panRecognizer_.state == UIGestureRecognizerStateBegan) {
    // If this pan is just starting, we've gotta do some setting up.
    // First, let's stop all animations
    targetPlacement_ = currentPlacement_;
    for (CALayer *subLayer in [cardLayers_ allValues]) {
      [subLayer removeAllAnimations];
    }
    
    // Set the recognizer's translation from the current card
    CALayer *currentCard = [self layerForPlacement:self.currentPlacement];
    displacement_ = [[currentCard valueForKey:kCardKeyDisplacement] floatValue];
    
    CGPoint translation = [panRecognizer_ translationInView:self];
    translation.x = displacement_ * cardSpacing_;
    [panRecognizer_ setTranslation:translation inView:self];
  }
  else {
    // This is an ongoing pan: our displacement is based on the recognizer's
    // translation.
    displacement_ = [panRecognizer_ translationInView:self].x / cardSpacing_;
  }
  
  if (panRecognizer_.state == UIGestureRecognizerStateEnded) {
    // This is the end of the pan, so move to the "most reasonable" card
    CGFloat speed = [panRecognizer_ velocityInView:self].x / cardSpacing_;
    
    int targetDisplacement = -(int)(displacement_ + (speed/2));
    [self centerOnCardAtInterval:targetDisplacement animated:YES];
  }
  else {
    // Switch current card?
    double overflow = fabs(displacement_) - 0.5;
    if (overflow > 0) {
      int placementDelta = 1 + floor(overflow);
      if (displacement_ > 0) placementDelta = -placementDelta;
      
      displacement_ += placementDelta;
      self.currentPlacement += placementDelta;
      
      // Update recognizer's translation
      CGPoint translation = [panRecognizer_ translationInView:self];
      translation.x = displacement_ * cardSpacing_;
      [panRecognizer_ setTranslation:translation inView:self];
      
      // Inform delegate
      if ([(id)delegate respondsToSelector:
           @selector(cardFlow:centeredOnCardAtIndex:)]) {
        [delegate cardFlow:self
     centeredOnCardAtIndex:[self indexOfCardAtPlacement:self.currentPlacement]];
      }
    }
    
    // Layout cards with no animation, since we're dragging
    [self layoutCardsOnDisplay:NO];
  }
}


#pragma mark Utilities

- (NSRange)rangeForPlacement:(NSInteger)placement {
  if (cardCount_ == 0) return NSMakeRange(0, 0);
  return NSMakeRange(placement - sideCards_, 1 + 2*sideCards_);
}

- (NSUInteger)indexOfCardAtPlacement:(NSInteger)placement {
  if (placement >= 0) return placement % cardCount_;
  
  // I checked this with pencil and paper.  Yes, it's kinda weird.
  return (cardCount_ - (-placement % cardCount_)) % cardCount_;
}


@end


#pragma mark -
#pragma mark Layout functions

NSDictionary *kXaeCardsViewCardDeckLayout(CGFloat displacement,
                                          XaeCardsView *view) {
  CGFloat width = view.bounds.size.width;
  CGFloat height = view.bounds.size.height;
  CGFloat absDisplacement = fabs(displacement);
  CGFloat spacing = view.cardSpacing;
  
  CATransform3D mat = CATransform3DMakeTranslation(width/2, height/2, -1);
  CGFloat x, y, z, theta;
  
  if (displacement > 1) displacement = spacing;
  else if (displacement < -1) displacement = -spacing;
  else displacement *= spacing;
  
  x = spacing * atan(4*displacement/spacing) / M_PI_2;
  y = -(displacement*displacement)/1000;
  z = -absDisplacement;
  
  theta = -(displacement/spacing) * M_PI_4;
  
  mat = CATransform3DTranslate(mat, x, y, z);
  mat = CATransform3DRotate(mat, theta, 0, 0, 1);
  
  return [NSDictionary dictionaryWithObject:[NSValue valueWithCATransform3D:mat]
                                     forKey:@"transform"];
}
