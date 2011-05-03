/**
 @file XaeCardsView.m
 
 Created by Diego Garcia on 5/1/11.
 Copyright 2011 Diego Garcia. All rights reserved.
 */

#import "XaeCardsViewController.h"

@implementation XaeCardsViewController

#pragma mark Properties

@synthesize cardsView = cardsView_;


#pragma mark Controller lifecycle

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
  
  self.cardsView.sideCards = 2;
}

- (void)viewDidUnload {
    [super viewDidUnload];
  
    // Release any retained subviews of the main view.
    self.cardsView = nil;
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}


#pragma mark - XaeCardsViewDataSource

- (UIView*)cardFlow:(XaeCardsView*)cardFlow cardAtIndex:(NSUInteger)index {
  UIView *cardView =
  [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 200)] autorelease];
  
  switch (index) {
    case 0: cardView.backgroundColor = [UIColor redColor]; break;
    case 1: cardView.backgroundColor = [UIColor greenColor]; break;
    case 2: cardView.backgroundColor = [UIColor blueColor]; break;
    default:
      cardView.backgroundColor = [UIColor blackColor];
      break;
  }
  
  return cardView;
}

- (NSUInteger)numberOfCardsInCardFlow:(XaeCardsView*)cardFlow { return 3; }


#pragma mark - XaeCardsViewDelegate

- (void)cardFlow:(XaeCardsView*)cardFlow
    centeredOnCardAtIndex:(NSUInteger)index {}

- (void)cardFlow:(XaeCardsView*)cardFlow
    tapOnCardAtIndex:(NSUInteger)index {}


@end
