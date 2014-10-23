//
//  EventsViewController.h
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol passOfflineObject <NSObject>

-(void)addOfflineObject:(PFObject*)object;

@end

@interface EventsViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITableView *tableView;
    IBOutlet UILabel *tableLabel;
    IBOutlet UIActivityIndicatorView *updateSpinner;
    IBOutlet UILabel *updateLabel;
}

-(IBAction)onClick:(id)sender;
-(void)addOffline:(PFObject*)offlineEvent;
@property(nonatomic, assign)id delegate;
@property (nonatomic, strong) NSMutableArray *offlineEvents;

@end
