//
//  DivvyDatasetViewPanel.m
//  
//  Written in 2011 by Joshua Lewis at the UC San Diego Natural Computation Lab,
//  PI Virginia de Sa, supported by NSF Award SES #0963071.
//  Copyright 2011, UC San Diego Natural Computation Lab. All rights reserved.
//  Licensed under the MIT License. http://www.opensource.org/licenses/mit-license.php
//
//  Find the Divvy project on the web at http://divvy.ucsd.edu

#import "DivvyDatasetViewPanel.h"
#import "DivvyAppDelegate.h"
#import "DivvyDatasetView.h"
#import "DivvyClusterer.h"


@implementation DivvyDatasetViewPanel

@synthesize datasetVisualizerView;
@synthesize pointVisualizerView;
@synthesize clustererView;
@synthesize reducerView;

@synthesize datasetVisualizerHeader;
@synthesize pointVisualizerHeader;
@synthesize clustererHeader;
@synthesize reducerHeader;

@synthesize datasetVisualizerArrayController;
@synthesize pointVisualizerArrayController;
@synthesize clustererArrayController;
@synthesize reducerArrayController;

@synthesize datasetVisualizerController;
@synthesize pointVisualizerController;
@synthesize clustererController;
@synthesize reducerController;

@synthesize selectViewTextField;

@synthesize scrollView;

@synthesize datasetVisualizerViewControllers;
@synthesize pointVisualizerViewControllers;
@synthesize clustererViewControllers;
@synthesize reducerViewControllers;

#pragma mark -
#pragma mark UI events
- (IBAction) datasetVisualizerSelect:(id)sender {
  [self reflow];
  
  DivvyAppDelegate *delegate = [NSApp delegate];
  
  delegate.selectedDatasetView.selectedDatasetVisualizer = pointVisualizerController.content;
  
  [delegate.selectedDatasetView datasetVisualizerChanged];
  [delegate reloadDatasetView:delegate.selectedDatasetView];
}

- (IBAction) pointVisualizerSelect:(id)sender {
  [self reflow];
  
  DivvyAppDelegate *delegate = [NSApp delegate];
  
  delegate.selectedDatasetView.selectedPointVisualizer = pointVisualizerController.content;
  
  [delegate.selectedDatasetView pointVisualizerChanged];
  [delegate reloadDatasetView:delegate.selectedDatasetView];
}

- (IBAction) clustererSelect:(id)sender {
  [self reflow];
  
  DivvyAppDelegate *delegate = [NSApp delegate];
  
  delegate.selectedDatasetView.selectedClusterer = clustererController.content;
  
  [delegate.selectedDatasetView datasetVisualizerChanged]; // If the clustering changes, the dataset visualizer result needs to be updated
  [delegate reloadDatasetView:delegate.selectedDatasetView];
}

- (IBAction) reducerSelect:(id)sender {
  [self reflow];
  
  DivvyAppDelegate *delegate = [NSApp delegate];
  
  delegate.selectedDatasetView.selectedReducer = reducerController.content;
  
  [delegate.selectedDatasetView datasetVisualizerChanged]; // If the reduction changes, the dataset visualizer result needs to be updated
  [delegate.selectedDatasetView pointVisualizerChanged]; // Same for the point visualizer
  [delegate reloadDatasetView:delegate.selectedDatasetView];
}

#pragma mark -
#pragma mark Redraw panel when state changes
- (void) reflow {
  DivvyAppDelegate *delegate = [NSApp delegate];
  NSArray *pluginTypes = delegate.pluginTypes;
  
  NSRect topFrame = self.view.frame;
  NSRect documentFrame = [self.scrollView.documentView frame];
  
  float y = -1.f; // Go from the top down, minus the top border pixel
  float headerBuffer = 0.f; // Buffer between bottom of header and top of view
  
  // Need to set documentFrame height before positioning the subviews
  for(NSString *pluginType in pluginTypes) {
    NSView *view = [self valueForKey:[NSString stringWithFormat:@"%@View", pluginType]];
    NSView *header = [self valueForKey:[NSString stringWithFormat:@"%@Header", pluginType]];
    
    if(delegate.selectedDatasetView) { // Remove subviews that have changed and adjust height for the new views
      NSArray *viewControllers = [self valueForKey:[NSString stringWithFormat:@"%@ViewControllers", pluginType]];
      NSArrayController *arrayController = [self valueForKey:[NSString stringWithFormat:@"%@ArrayController", pluginType]];
      NSObjectController *objectController = [self valueForKey:[NSString stringWithFormat:@"%@Controller", pluginType]];

      NSViewController *aController;
      
      aController = [viewControllers objectAtIndex:[arrayController.arrangedObjects indexOfObject:[objectController content]]];
      
      for(NSView *aView in view.subviews)
        if(aView != aController.view) // Pointer comparison should work, since there's only one instance of each ViewController
          [aView removeFromSuperview];
      
      NSRect subFrame = [[aController view] frame];
      NSRect headerFrame = [header frame];
      
      y += subFrame.size.height;
      y += headerFrame.size.height + headerBuffer;
    }
    else { // Remove all subviews
      for(NSView *aView in view.subviews)
        [aView removeFromSuperview];
    }
  }

  y += delegate.selectedDatasetView ? -1.f : 50.f; // Top border, with room for select label if nothing's selected
  
  
  documentFrame.origin.y = topFrame.origin.y + topFrame.size.height - y;
  documentFrame.size.height = y;
  [self.scrollView.documentView setFrame:documentFrame]; // display:YES animate:NO];
  
  //y = 0.f; // Reset to position subviews
  
  for(NSString *pluginType in pluginTypes) {
    NSView *view = [self valueForKey:[NSString stringWithFormat:@"%@View", pluginType]];
    NSView *header = [self valueForKey:[NSString stringWithFormat:@"%@Header", pluginType]];
    
    if(delegate.selectedDatasetView) {
      
      NSArray *viewControllers = [self valueForKey:[NSString stringWithFormat:@"%@ViewControllers", pluginType]];
      NSArrayController *arrayController = [self valueForKey:[NSString stringWithFormat:@"%@ArrayController", pluginType]];
      NSObjectController *objectController = [self valueForKey:[NSString stringWithFormat:@"%@Controller", pluginType]];
      NSViewController *aController;
      
      aController = [viewControllers objectAtIndex:[arrayController.arrangedObjects indexOfObject:[objectController content]]];
      
      NSRect subFrame = [[aController view] frame];
      NSRect frame = [view frame];
      NSRect headerFrame = [header frame];

      y -= subFrame.size.height;
      frame.origin.y = y;
      frame.size.height = subFrame.size.height;
      
      y -= headerFrame.size.height + headerBuffer;
      headerFrame.origin.y = y;
      
      [view setFrame:frame];
      [header setFrame:headerFrame];
    
      if([view.subviews count] == 0) // Will happen only if we've changed views
        [view addSubview:[aController view]];
    }
  }
  
  NSRect selectViewFrame = [selectViewTextField frame];
  selectViewFrame.origin.y = 20.f;
  [selectViewTextField setFrame:selectViewFrame];
}

#pragma mark -
#pragma mark load/dealloc
// Called in applicationDidFinishLaunching
- (void) loadPluginViewControllers {
  DivvyAppDelegate *delegate = [NSApp delegate];
  NSArray *pluginTypes = delegate.pluginTypes;
  
  for(NSString *pluginType in pluginTypes) {
    NSMutableArray *pluginViewControllers = [NSMutableArray array];
    [self setValue:pluginViewControllers forKey:[NSString stringWithFormat:@"%@ViewControllers", pluginType]];
    
    for(NSEntityDescription *anEntityDescription in [[[NSApp delegate] managedObjectModel] entities])
      if([anEntityDescription.propertiesByName objectForKey:[NSString stringWithFormat:@"%@ID", pluginType]]) {        
        Class controller = NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"Divvy", anEntityDescription.name, @"Controller"]);
        
        id controllerInstance = [[controller alloc] init];
        [pluginViewControllers addObject:controllerInstance];
        [controllerInstance release];
        
        NSString *nibName = [NSString stringWithFormat:@"%@%@", @"Divvy", anEntityDescription.name];
        [NSBundle loadNibNamed:nibName owner:controllerInstance];
      }
  }
}

- (void) dealloc {
  [datasetVisualizerViewControllers release];
  [pointVisualizerViewControllers release];
  [clustererViewControllers release];
  [reducerViewControllers release];
  
  [datasetVisualizerView release];
  [pointVisualizerView release];
  [clustererView release];
  [reducerView release];
  
  [datasetVisualizerHeader release];
  [pointVisualizerHeader release];
  [clustererHeader release];
  [reducerHeader release];
  
  [datasetVisualizerArrayController release];
  [pointVisualizerArrayController release];
  [clustererArrayController release];
  [reducerArrayController release];
  
  [datasetVisualizerController release];
  [pointVisualizerController release];
  [clustererController release];
  [reducerController release];
  
  [selectViewTextField release];
  
  [scrollView release];
  
  [super dealloc];
}

@end
