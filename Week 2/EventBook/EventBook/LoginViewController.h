//
//  LoginViewController.h
//  EventBook
//
//  Created by Matthew Lewis on 10/6/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
{
    IBOutlet UITextField *userName;
    IBOutlet UITextField *password;
    IBOutlet UISwitch *saveToggle;
    IBOutlet UIButton *closeButton;
    IBOutlet UILabel *errorText;
}

-(IBAction)onClick:(id)sender;
-(IBAction)valueChanged:(UISwitch*)sender;

@end

