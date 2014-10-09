//
//  EventsViewController.h
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITableView *tableView;
}

-(IBAction)onClick:(id)sender;

@end
