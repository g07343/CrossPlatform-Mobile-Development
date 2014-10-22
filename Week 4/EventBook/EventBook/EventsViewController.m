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
NSMutableArray *eventMonths;
NSMutableArray *eventDays;
NSMutableArray *eventHours;
NSMutableArray *eventMinutes;
NSMutableArray *eventNames;

int selectedEvent;
bool isEditing;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up a long press gesture listener for use with our table view
    UILongPressGestureRecognizer *longRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [tableView addGestureRecognizer:longRecognizer];
    
    //set numLines for tableLabel here, because doing it on the storyboard generates an annoying warning
    tableLabel.numberOfLines = 2;
    
    //set up initial value for our isEditing bool to false
    isEditing = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    //reset our label by default
    tableLabel.text = @"Your events:";
    tableLabel.textColor = [UIColor blackColor];
    
    //ensure we're updating the table view whenever the view appears
    [self updateTableView];
}

//this method is responsible for keeping our table view updated with the remote data,
//and is fired whenever this activity becomes visible, or when the user deletes and item
-(void)updateTableView {
    //grab whatever events are stored on Parse for this account
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // set up our arrays to store data
            eventArray = [NSMutableArray arrayWithCapacity:objects.count];
            eventIds = [NSMutableArray arrayWithCapacity:objects.count];
            eventMonths = [NSMutableArray arrayWithCapacity:objects.count];
            eventDays = [NSMutableArray arrayWithCapacity:objects.count];
            eventHours = [NSMutableArray arrayWithCapacity:objects.count];
            eventMinutes = [NSMutableArray arrayWithCapacity:objects.count];
            eventNames = [NSMutableArray arrayWithCapacity:objects.count];
            
            if (objects.count > 0) {
                // grab the data we need from each found event
                for (int i = 0; i < objects.count; i ++) {
                    PFObject *object = objects[i];
                    NSString *eventTitle = object[@"name"];
                    int month = [[object objectForKey:@"month"] intValue];
                    int day = [[object objectForKey:@"day"] intValue];
                    int hour = [[object objectForKey:@"hour"] intValue];
                    int minute = [[object objectForKey:@"minute"] intValue];
                    NSString *eventId = object.objectId;
                    NSString *formattedString = [NSString stringWithFormat:@"%@:  %d/%d  at  %d:%d", eventTitle, month, day, hour, minute];
                    
                    //add final values to our arrays used to populate our table view
                    eventArray[i] = formattedString;
                    eventIds[i] = eventId;
                    
                    //need to convert ints to NSNumbers so we can store in an array unfortunately
                    NSNumber *monthConverted = [NSNumber numberWithInt:month];
                    NSNumber *dayConverted = [NSNumber numberWithInt:day];
                    NSNumber *hourConverted = [NSNumber numberWithInt:hour];
                    NSNumber *minuteConverted = [NSNumber numberWithInt:minute];
                    
                    //add retrieved data to arrays
                    eventNames [i]= eventTitle;
                    eventMonths[i] = monthConverted;
                    eventDays[i] = dayConverted;
                    eventHours[i] = hourConverted;
                    eventMinutes[i] = minuteConverted;
                    
                    
                }
            } else {
                //no events saved to this account, so modify text view to inform user
                tableLabel.text = @"No events found.  Tap the '+' button above to get started!";
                tableLabel.textColor = [UIColor redColor];
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

//method to detect when the user selects an item in the TableView by tapping it
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //set our 'selectedEvent' int to item user selected and send to the 'add' activity, which will pull double duty as our editor as well
    selectedEvent = indexPath.row;
    
    //set our bool to true so that the 'add' activity knows to populate its data
    isEditing = true;
    
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AddViewController *addView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddViewController"];
    
    
    //set the data within the new view controller
    addView.eventTitle = eventNames[indexPath.row];
    addView.eventId = eventIds[indexPath.row];
    addView.eventMonth = eventMonths[indexPath.row];
    addView.eventDay = eventDays[indexPath.row];
    addView.eventHour = eventHours[indexPath.row];
    addView.eventMinute = eventMinutes[indexPath.row];
    
    [self presentViewController:addView animated:YES completion:nil];
}

-(IBAction)onClick:(id)sender {
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0) {
        //user tapped the 'logout' button
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to return to the login screen?  You will be logged out." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        alert.tag = 0;
        [alert show];
    } else if (button.tag == 1) {
        //user tapped the 'add' button
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *addView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddViewController"];
        [self presentViewController:addView animated:YES completion:nil];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        //logout alert view
        if (buttonIndex == 1) {
            [PFUser logOut];
            [self dismissViewControllerAnimated:true completion:nil];
        
        }
    } else if (alertView.tag == 1) {
        //delete event alert view
        if (buttonIndex == 1) {
            [self deleteEvent:selectedEvent];
        }
    }
    
}

//this method fires when the user long presses on the table view
-(void)longPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    //grab the point that is being long pressed
    CGPoint point = [gestureRecognizer locationInView:tableView];
    
    //grab the index that the point is over
    NSIndexPath *index = [tableView indexPathForRowAtPoint:point];
    
    if (index == nil) {
        NSLog(@"long pressed on table view but not a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long pressing tableView row:  %d", index.row);
        
        //set to global var so we can delete if the user wishes
        selectedEvent = index.row;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Event" message:@"Are you sure you want to delete this event?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        alert.tag = 1;
        [alert show];
    }
}


//this method takes care of deleting a specific event from the tableview
-(void)deleteEvent:(int)index {
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    
    [query getObjectInBackgroundWithId:eventIds[selectedEvent] block:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"Error retrieving object from Parse!");
        } else {
            //object retrieved from parse successfully, so delete it and refresh table view
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded && error == nil) {
                    [self updateTableView];
                }
            }];
        }
    }];
}
@end