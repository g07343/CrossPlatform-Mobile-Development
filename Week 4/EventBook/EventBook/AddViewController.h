//
//  AddViewController.h
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddViewController : UIViewController
{
    IBOutlet UITextField *eventNameField;
    IBOutlet UIDatePicker *datePicker;
    IBOutlet UIButton *closeKeyboard;
}

-(IBAction)onClick:(id)sender;

@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, strong) NSString *eventId;
@property (nonatomic, strong) NSNumber *eventMonth;
@property (nonatomic, strong) NSNumber *eventDay;
@property (nonatomic, strong) NSNumber *eventHour;
@property (nonatomic, strong) NSNumber *eventMinute;
@end
