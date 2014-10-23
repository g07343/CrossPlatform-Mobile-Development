//
//  AddViewController.m
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "AddViewController.h"
#import <Parse/Parse.h>
#import "NetworkManager.h"

@interface AddViewController ()

@end

@implementation AddViewController

@synthesize eventTitle, eventId, eventMonth, eventDay, eventHour, eventMinute;
NSDate *selectedDate;



- (void)viewDidLoad {
    [super viewDidLoad];
    // add listener to our date picker to keep track of the date selected
    [datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    
    //hide keyboard button by default
    closeKeyboard.hidden = true;
    
    //add listeners for when the keyboard appears and disappears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:)name:UIKeyboardWillHideNotification object:nil];
    
    //check to see if we are supposed to be editing an already created event
    if (eventTitle != nil) {
        NSLog(@"Passed event name was:  %@", eventTitle);
        
        //jump through hoops since there is no simple way to create an NSDate object from NSNumbers...
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        
        //convert back to ints
        int convertedDay = [eventDay integerValue];
        int convertedMonth = [eventMonth integerValue];
        int convertedHour = [eventHour integerValue];
        int convertedMinute = [eventMinute integerValue];
        
        //set newly converted ints to our date components object
        [comps setDay:convertedDay];
        [comps setMonth:convertedMonth];
        [comps setHour:convertedHour];
        [comps setMinute:convertedMinute];
        
        //create an NSCalendar to use to convert date components to an actual date object
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        //FINALLY...convert to an NSDate
        NSDate *eventDate = [calendar dateFromComponents:comps];
        
        [eventNameField setText:eventTitle];
        [datePicker setDate:eventDate];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button.tag == 0) {
    //user tapped cancel button, so return to view activity
        [self dismissViewControllerAnimated:true completion:nil];
    
    } else if (button.tag == 1) {
    //user tapped the save button
        NSString *eventName = eventNameField.text;
        
        //ensure the name for the event was chosen
        if (eventName.length > 0) {
            NSDate *chosenDate = [datePicker date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MM"];
            NSString *formattedMonth = [formatter stringFromDate:chosenDate];
            int month = [formattedMonth intValue];
            [formatter setDateFormat:@"dd"];
            NSString *formattedDay = [formatter stringFromDate:chosenDate];
            int day = [formattedDay intValue];
            [formatter setDateFormat:@"hh"];
            NSString *formattedHour = [formatter stringFromDate:chosenDate];
            int hour = [formattedHour intValue];
            [formatter setDateFormat:@"mm"];
            NSString *formattedMinute = [formatter stringFromDate:chosenDate];
            int minute = [formattedMinute intValue];
            NSLog(@"");
            
            //ensure we have a network connection
            bool isConnected = [[NetworkManager GetIntance] networkConnected];
            if (isConnected) {
                NSLog(@"Network Connected in add!");
                //network enabled
                //check whether we are editing or if we are currently creating a new event
                if (eventTitle != nil) {
                    //grab the original object from parse so we can modify it
                    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
                    [query whereKey:@"objectId" equalTo:eventId];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            PFObject *oldObject = objects[0];
                            
                            //create an int counter to track the number of items that were changed
                            int itemsUpdated = 0;
                            
                            //only update the data that was changed
                            if (![eventTitle isEqualToString:eventName]) {
                                oldObject[@"name"] = eventName;
                                itemsUpdated ++;
                                NSLog(@"name");
                            }
                            
                            //convert original values back to ints for comparison
                            int convertedDay = [eventDay integerValue];
                            int convertedMonth = [eventMonth integerValue];
                            int convertedHour = [eventHour integerValue];
                            int convertedMinute = [eventMinute integerValue];
                            
                            if (convertedMonth != month) {
                                oldObject[@"month"] = @(month);
                                itemsUpdated ++;
                                NSLog(@"month");
                            }
                            
                            if (convertedDay != day) {
                                oldObject[@"day"] = @(day);
                                itemsUpdated ++;
                                NSLog(@"day");
                            }
                            
                            if (convertedHour != hour) {
                                oldObject[@"hour"] = @(hour);
                                itemsUpdated ++;
                                NSLog(@"hour");
                            }
                            
                            if (convertedMinute != minute) {
                                oldObject[@"minute"] = @(minute);
                                itemsUpdated ++;
                                NSLog(@"minute");
                            }
                            
                            //save out the newly created object only if at least one thing was changed
                            if (itemsUpdated > 0) {
                                NSLog(@"Number of items updated was:  %d", itemsUpdated);
                                [oldObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    if (succeeded) {
                                        
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
                                        [token saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                                            if (succeeded) {
                                                [self dismissViewControllerAnimated:true completion:nil];
                                            }
                                        }];
                                        
                                        
                                    }
                                }];
                            } else {
                                //no changes were made, so let the user know
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Changes" message:@"Please change your event to edit it." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                                
                                [alert show];
                            }
                        }
                    }];
                    
                } else {
                    //now that we have all of the data, save it out to the user's account on parse
                    PFObject *event = [PFObject objectWithClassName:@"Event"];
                    event[@"name"] = eventName;
                    event[@"month"] = @(month);
                    event[@"day"] = @(day);
                    event[@"hour"] = @(hour);
                    event[@"minute"] = @(minute);
                    
                    //set the ACL restriction to the current user
                    event.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                    
                    [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                        if (succeeded) {
                            
                            //create a token object to signal other devices with app open
                            
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
                            [token saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                                if (succeeded) {
                                    [self dismissViewControllerAnimated:true completion:nil];
                                }
                            }];
                        } else {
                            
                        }
                    }];
                }
                
                
            } else {
                
                
                //no internet connection, alert user
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection" message:@"You do not currently have a network connection.  Please reconnect to the internet before creating or modifying your event." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                [alert show];
            }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Name Required" message:@"Please choose a name for your event" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                [alert show];
            }
            
            
        
        
    } else if (button.tag == 2) {
        //close keyboard
        [eventNameField resignFirstResponder];
    }
}

//this method simply updates our local value for whatever
-(void)dateChanged {
    selectedDate = datePicker.date;
}

-(void)keyboardWillShow:(NSNotification *)notification {
    //show our 'close' button, so the user can hide the keyboard when done editing
    closeKeyboard.hidden = false;
}

-(void)keyboardWillHide:(NSNotification *)notification {
    //hide our 'close' button again
    closeKeyboard.hidden = true;
}

//this method lets us keep the user from selecting a date older than today
-(IBAction)datePickerChanged:(id)sender {
    //create the 'now' date
    NSDate *now = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)0];
    
    if ( [ datePicker.date timeIntervalSinceNow ] < 0 )
        datePicker.date = now;
}

@end
