//
//  AddViewController.h
//  EventBook
//
//  Created by Matthew Lewis on 10/8/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol sendOfflineObject <NSObject>

-(void)addOffline:(PFObject*)object;

@end

@interface AddViewController : UIViewController <UIAlertViewDelegate>
{
    IBOutlet UITextField *eventNameField;
    IBOutlet UIDatePicker *datePicker;
    IBOutlet UIButton *closeKeyboard;
}

-(IBAction)onClick:(id)sender;
-(IBAction)datePickerChanged:(id)sender;



@property(nonatomic, assign)id delegate;
@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, strong) NSString *eventId;
@property (nonatomic, strong) NSNumber *eventMonth;
@property (nonatomic, strong) NSNumber *eventDay;
@property (nonatomic, strong) NSNumber *eventHour;
@property (nonatomic, strong) NSNumber *eventMinute;
@end
