//
//  EventsViewController.m
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "EventsViewController.h"
#import <Parse/Parse.h>
#import "AddViewController.h"

@interface EventsViewController () 

@end

@implementation EventsViewController

NSMutableArray *eventArray;
NSMutableArray *eventIds;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear runs!");
    [self updateTableView];
}

-(void)updateTableView {
    NSLog(@"updateTableView runs!");
    //grab whatever events are stored on Parse for this account
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // set up our arrays to store data
            eventArray = [NSMutableArray arrayWithCapacity:objects.count];
            eventIds = [NSMutableArray arrayWithCapacity:objects.count];
            
            // grab the data we need from each found event
            for (int i = 0; i < objects.count; i ++) {
                PFObject *object = objects[i];
                NSString *eventTitle = object[@"name"];
                int month = [[object objectForKey:@"month"] intValue];
                int day = [[object objectForKey:@"day"] intValue];
                int hour = [[object objectForKey:@"hour"] intValue];
                int minute = [[object objectForKey:@"minute"] intValue];
                NSString *eventId = object.objectId;
                NSString *formattedString = [NSString stringWithFormat:@"%@ :  %d / %d  at  %d : %d", eventTitle, month, day, hour, minute];
                
                //add final values to our arrays used to populate our table view
                eventArray[i] = formattedString;
                eventIds[i] = eventId;
            }
            
            
            [tableView reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [eventArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView1 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    UITableViewCell *cell = [tableView1 dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [eventArray objectAtIndex:indexPath.row];
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)onClick:(id)sender {
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0) {
        //user tapped the 'logout' button
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to return to the login screen?  You will be logged out." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [alert show];
    } else if (button.tag == 1) {
        //user tapped the 'add' button
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *addView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddViewController"];
        [self presentViewController:addView animated:YES completion:nil];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [PFUser logOut];
        [self dismissViewControllerAnimated:true completion:nil];
    }
}

@end
