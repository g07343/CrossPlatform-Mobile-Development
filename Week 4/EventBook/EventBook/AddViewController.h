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

@end
