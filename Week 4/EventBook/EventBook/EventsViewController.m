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
#import "NetworkManager.h"

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

//mutable array to hold arrays of 'offline' events that were added
@synthesize offlineEvents;
@synthesize delegate;

bool updatedOffline;

int selectedEvent;
bool isEditing;
NSTimer *pollingTimer;
int updateCounter;
bool wasDisplayed;

-(void)passOfflineObject:(PFObject*)object {
    [delegate addOfflineObject:object];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up a long press gesture listener for use with our table view
    UILongPressGestureRecognizer *longRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [tableView addGestureRecognizer:longRecognizer];
    
    //set numLines for tableLabel here, because doing it on the storyboard generates an annoying warning
    tableLabel.numberOfLines = 2;
    
    //set up initial value for our isEditing bool to false
    isEditing = false;
    
    //set initial value for our polling counter
    updateCounter = 0;
    
    //set initial bool for 'wasDisplayed'
    wasDisplayed = false;
    
    //set up a timer to poll parse
    //pollingTimer = [NSTimer scheduledTimerWithTimeInterval:15.0f target:self selector:@selector(pollParse) userInfo:nil repeats:YES];
    
    //if we aren't currently connected to the internet, set up our mutable array to hold events that are created 'offline'
    offlineEvents = [[NSMutableArray alloc] init];
    
    //set our update ui to be hidden by default
    [updateSpinner stopAnimating];
    updateSpinner.hidden = YES;
    updateLabel.hidden = YES;
}

-(void)pollParse {
    NSLog(@"pollParse function runs!");
    bool isConnected = [[NetworkManager GetIntance] networkConnected];
    if (isConnected) {
        PFUser *current = [PFUser currentUser];
        if (current != nil) {
            //check if we have any events that were saved while offline
            if ([offlineEvents count] > 0) {
                //we have at least one event created while offline, so save
                for (int i = 0; i < [offlineEvents count]; i++) {
                    PFObject *savedObject = [offlineEvents objectAtIndex:i];
                    [savedObject saveInBackground];
                }
                
                //create an update token to alert other running devices
                PFObject *token = [[PFObject alloc] initWithClassName:@"wasUpdated"];
                int value;
                value = (arc4random());
                NSString *convertedInt = [NSString stringWithFormat:@"%i", value];
                
                //store token value to  user prefs
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setValue:convertedInt forKey:@"editKey"];
                [defaults synchronize];
                
                //set id value to the PFObject
                token[@"editKey"] = convertedInt;
                
                
                token.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                [token saveInBackground];
            }
            
            //grab local 'update' key to check against one on Parse (if there is one)
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            NSString *lastKey = [defaults valueForKey:@"editKey"];
            
            //grab any remote update 'tokens' for this account
            PFQuery *query = [PFQuery queryWithClassName:@"wasUpdated"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                //ensure we have at least one object
                if (objects != nil && objects.count > 0) {
                    //grab the first item to check it's value
                    PFObject *remoteToken = [objects objectAtIndex:0];
                    
                    //grab the attached string to compare
                    NSString *remoteKey = [remoteToken objectForKey:@"editKey"];
                    
                    //compare the string, if different, data was updated somewhere else so pull new data
                    if (![lastKey isEqualToString:remoteKey]) {
                        NSLog(@"Update keys were different!");
                        updateCounter ++;
                        if (updateCounter > 2) {
                            //reset our counter
                            updateCounter = 0;
                            
                            //delete remote token
                            NSString *deleteKey = [remoteToken objectId];
                            PFQuery *deleteQuery = [PFQuery queryWithClassName:@"wasUpdated"];
                            [deleteQuery getObjectInBackgroundWithId:deleteKey block:^(PFObject *object, NSError *error) {
                                if (!error) {
                                    //delete this update key since there has been enough time for everything to update across devices
                                    [object deleteInBackground];
                                }
                            }];
                        }
                        //update remote data
                        [self updateTableView];
                    }
                }
            }];
        } else {
            if (wasDisplayed == false) {
                if ([offlineEvents count] > 0) {
                    //there was at least one offline event saved, so inform user they need to login in order to save them
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Reestablished" message:@"Internet connection restored.  You aren't currently logged in.  Log in now?  NOTE: Your offline events will be saved to whichever account you log into.  This message will not show again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
                    alert.tag = 20;
                    [alert show];
                    
                } else {
                    //no current user, so offer login
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Reestablished" message:@"Internet connection restored.  You aren't currently logged in.  Log in now?  NOTE: You will return to the login screen.  This message will not show again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
                    alert.tag = 25;
                    [alert show];
                }
                //set boolean to true so we aren't showing this alert every 15 seconds after network restoration
                wasDisplayed = true;
            }
        }
    } else {
        //no network
        tableLabel.text = @"No network detected.  Running in offline mode.";
        tableLabel.textColor = [UIColor redColor];
    }
}

//this allows us to detect which choice the user selects when trying to log in with no network connection
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //ensure we are only checking the alert that displays when trying to log in
    if (alertView.tag == 25) {
        if (buttonIndex == 1) {
            [self dismissViewControllerAnimated:true completion:nil];
        }
    } else if (alertView.tag == 20) {
        if (buttonIndex == 1) {
            NSLog(@"user wants to log out and save items!");
            for (int i = 0; i < [offlineEvents count]; i ++) {
                PFObject *object = [offlineEvents objectAtIndex:i];
                [self passOfflineObject:object];
            }
            [self dismissViewControllerAnimated:true completion:nil];
        }
    } else if (alertView.tag == 50) {
        if (buttonIndex == 1) {
            [PFUser logOut];
            [self dismissViewControllerAnimated:true completion:nil];
        }
    } else if (alertView.tag == 51) {
        if (buttonIndex == 1) {
            [self deleteEvent:selectedEvent];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    //reset our label by default
    tableLabel.text = @"Your events:";
    tableLabel.textColor = [UIColor blackColor];
    
    //ensure we're updating the table view whenever the view appears (if we have internet)
    bool nowConnected = [[NetworkManager GetIntance] networkConnected];
    if (nowConnected) {
        [self updateTableView];
    }
    
    //also, ensure we have a valid timer going
    if (pollingTimer == nil) {
        pollingTimer = [NSTimer scheduledTimerWithTimeInterval:15.0f target:self selector:@selector(pollParse) userInfo:nil repeats:YES];
    }
    
    //ensure that our 'offline' mutable array is valid in case connectivity was lost during the 'add' activity
    bool isConnected = [[NetworkManager GetIntance] networkConnected];
    if (!(isConnected)) {
        //add items to our offline array if we created something in the add acitivty while offline
        if (updatedOffline == true) {
            if (offlineEvents != nil) {
                //ensure our offline array isn't nil even though it shouldn't be
                int indexCorrector = [offlineEvents count] -1;
                
                PFObject *offlineObject = [offlineEvents objectAtIndex:indexCorrector];
                
                //grab all of the needed data from the event
                NSString *eventTitle = offlineObject[@"name"];
                int month = [[offlineObject objectForKey:@"month"] intValue];
                int day = [[offlineObject objectForKey:@"day"] intValue];
                int hour = [[offlineObject objectForKey:@"hour"] intValue];
                int minute = [[offlineObject objectForKey:@"minute"] intValue];
                
                NSString *formattedString = [NSString stringWithFormat:@"%@:  %d/%d  at  %d:%d", eventTitle, month, day, hour, minute];
                
                //need to convert ints to NSNumbers so we can store in an array unfortunately
                NSNumber *monthConverted = [NSNumber numberWithInt:month];
                NSNumber *dayConverted = [NSNumber numberWithInt:day];
                NSNumber *hourConverted = [NSNumber numberWithInt:hour];
                NSNumber *minuteConverted = [NSNumber numberWithInt:minute];
                
                //check to see if we already have valid mutable arrays or not
                if (eventArray == nil) {
                    eventArray = [[NSMutableArray alloc] init];
                    eventIds = [[NSMutableArray alloc] init];
                    eventMonths = [[NSMutableArray alloc] init];
                    eventDays = [[NSMutableArray alloc] init];
                    eventHours = [[NSMutableArray alloc] init];
                    eventMinutes = [[NSMutableArray alloc] init];
                    eventNames = [[NSMutableArray alloc] init];
                }
                [eventArray addObject: formattedString];
                [eventIds addObject:@"noID"];
                [eventMonths addObject:monthConverted];
                [eventDays addObject:dayConverted];
                [eventHours addObject:hourConverted];
                [eventMinutes addObject:minuteConverted];
                
                
            }
            
            //reset boolean
            updatedOffline = false;
            
            //attempt to reflect all data in the table view
            [tableView reloadData];
        }
        
    }
    if (offlineEvents != nil) {
        NSLog(@"offline events is not nil and number of items:  %d", offlineEvents.count);
    } else {
        NSLog(@"offline events array was nil!");
    }
}

//we use this function to add offline events manually from the 'add' class
-(void)addOffline:(PFObject*)offlineEvent {
    if (offlineEvents == nil) {
        offlineEvents = [[NSMutableArray alloc] init];
    }
    [offlineEvents addObject:offlineEvent];
    
    //set our bool to true so that we know something was update within "viewWillAppear"
    updatedOffline = true;
    NSLog(@"Offline event added!");
}

//use this to pause our timer from running needlessly
-(void)viewWillDisappear:(BOOL)animated {
    if (pollingTimer != nil) {
        [pollingTimer invalidate];
        pollingTimer = nil;
    }
}

//this method is responsible for keeping our table view updated with the remote data,
//and is fired whenever this activity becomes visible, or when the user deletes and item
-(void)updateTableView {
    //ensure we have a valid network connection
    bool isConnected = [[NetworkManager GetIntance] networkConnected];
    if (isConnected) {
        //internet connection is good, ensure we have a logged in user
        PFUser *current = [PFUser currentUser];
        if (current != nil) {
            //user is logged in, so go ahead and pull data
            //grab whatever events are stored on Parse for this account
            PFQuery *query = [PFQuery queryWithClassName:@"Event"];
            
            //since we are updating, inform user that progress is happening
            [updateSpinner startAnimating];
            updateSpinner.hidden = NO;
            updateLabel.hidden = NO;
            
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
                        //ensure our label is correct
                        tableLabel.text = @"Your events:";
                        tableLabel.textColor = [UIColor blackColor];
                        
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
                    //set our updating indicators to not be visible since update is done
                    [updateSpinner stopAnimating];
                    updateSpinner.hidden = YES;
                    updateLabel.hidden = YES;
                    
                    [tableView reloadData];
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        } else {
            //no user was logged in, so offer login
            
        }
    
    } else {
        //no network connection found
        tableLabel.text = @"No network detected.  Running in offline mode.";
        tableLabel.textColor = [UIColor redColor];
    }
    
    
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
    bool isConnected = [[NetworkManager GetIntance] networkConnected];
    if (isConnected == true) {
        NSLog(@"internet found within selection method");
        if ([PFUser currentUser] != nil) {
            //set our 'selectedEvent' int to item user selected and send to the 'add' activity, which will pull double duty as our editor as well
            selectedEvent = indexPath.row;
            
            //set our bool to true so that the 'add' activity knows to populate its data
            isEditing = true;
            
            UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            AddViewController *addView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddViewController"];
            
            //set this as the delegate to the addViewController
            addView.delegate = self;
            
            //set the data within the new view controller
            addView.eventTitle = eventNames[indexPath.row];
            addView.eventId = eventIds[indexPath.row];
            addView.eventMonth = eventMonths[indexPath.row];
            addView.eventDay = eventDays[indexPath.row];
            addView.eventHour = eventHours[indexPath.row];
            addView.eventMinute = eventMinutes[indexPath.row];
            
            [self presentViewController:addView animated:YES completion:nil];
        } else {
            //no logged in user
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection" message:@"You aren't currently logged in.  Please login to edit an event." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alert show];
        }
        
    } else {
        //no internet
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection" message:@"You aren't currently connected to the internet.  Cannot edit an event while offline." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(IBAction)onClick:(id)sender {
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0) {
        //user tapped the 'logout' button
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to return to the login screen?  You will be logged out." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        alert.tag = 50;
        [alert show];
    } else if (button.tag == 1) {
        //user tapped the 'add' button
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AddViewController *addView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddViewController"];
        
        //set the delegate to this activity
        addView.delegate = self;
        [self presentViewController:addView animated:YES completion:nil];
    }
}

//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (alertView.tag == 0) {
//        //logout alert view
//        if (buttonIndex == 1) {
//            [PFUser logOut];
//            [self dismissViewControllerAnimated:true completion:nil];
//        
//        }
//    } else if (alertView.tag == 1) {
//        //delete event alert view
//        if (buttonIndex == 1) {
//            [self deleteEvent:selectedEvent];
//        }
//    }
//    
//}

//this method fires when the user long presses on the table view
-(void)longPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    bool isConnected = [[NetworkManager GetIntance] networkConnected];
    if (isConnected) {
        if ([PFUser currentUser] == nil) {
           //no logged in user
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection" message:@"You aren't currently logged in.  Please login to delete an event." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alert show];
        } else {
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
                alert.tag = 51;
                [alert show];
            }
        }
        
    } else {
        //no internet
        //no internet
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection" message:@"You aren't currently connected to the internet.  Cannot delete an event while offline." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
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
            
            //create update token to signal other open user devices to update their data
            //create an update 'token' so that other devices running the app know data was updated
            PFObject *token = [[PFObject alloc] initWithClassName:@"wasUpdated"];
            int value;
            value = (arc4random());
            NSString *convertedInt = [NSString stringWithFormat:@"%i", value];
            
            //store token value to  user prefs
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:convertedInt forKey:@"editKey"];
            [defaults synchronize];
            
            //set id value to the PFObject
            token[@"editKey"] = convertedInt;
            
            
            token.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [token saveInBackground];
        }
    }];
}
@end
