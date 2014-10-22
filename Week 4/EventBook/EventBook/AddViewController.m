//
//  AddViewController.m
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "AddViewController.h"
#import <Parse/Parse.h>

@interface AddViewController ()

@end

@implementation AddViewController

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
                    [self dismissViewControllerAnimated:true completion:nil];
                } else {
                    
                }
            }];
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

@end
