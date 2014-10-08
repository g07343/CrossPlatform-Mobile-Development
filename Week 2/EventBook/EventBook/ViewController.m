//
//  ViewController.m
//  EventBook
//
//  Created by Matthew Lewis on 10/6/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //hide our close keyboard button by default
    closeButton.hidden = true;
    
    //hide our error text by default
    errorText.hidden = true;
    errorText.numberOfLines = 3;
    
    // parse test
    //PFObject *testObject = [PFObject objectWithClassName:@"TestObject"];
    //testObject[@"foo"] = @"bar";
    //[testObject saveInBackground];
    
    //add listeners for when the keyboard appears and disappears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:)name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//method to run whenever the user taps a button within the login form
-(IBAction)onClick:(id)sender {
    //grab all data we'll need
    NSString *name = userName.text;
    NSString *pass = password.text;
    int nameLength = name.length;
    int passLength = pass.length;
    
    //cast a button object to the 'sender' id so we can differentiate between the two
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0)
    {//login button tapped
        if (nameLength > 0) {
            if (passLength > 0) {
                //attempt to log in the user using the supplied credentials
                [PFUser logInWithUsernameInBackground:name password:pass block:^(PFUser *user, NSError *error) {
                    if (user) {
                        //log in successful, send to 'view' activity
                        
                    } else {
                       //error logging in, alert user
                        [self showError:@"login"];
                    }
                }];
            } else {
                [self showError:@"password"];
            }
        } else {
            [self showError:@"userName"];
        }
    } else if (button.tag == 1) {
        //create new button tapped
        NSLog(@"Username is:  %@ and password is: %@", name, pass);
        NSLog(@"Length of username is:  %d", nameLength);
        
        //ensure the user input a username and password
        if (nameLength > 0) {
            if (passLength > 0) {
                //credentials supplied correctly, so attempt to register a new user
                PFUser *user = [PFUser user];
                user.username = name;
                user.password = pass;
                
                //now send it to parse and check the the response
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        //new user created, send to the 'view' activity
                        NSLog(@"user created!");
                    } else {
                        //error signing up so alert user
                        [self showError:@"signUp"];
                    }
                }];
                
            } else {
                //user didn't input a password so show error
                [self showError:@"password"];
            }
        } else {
            //user didn't input a user name
            [self showError:@"userName"];
        }
        
    } else if (button.tag == 2) {
        //close keyboard button tapped
        [userName resignFirstResponder];
        [password resignFirstResponder];
    }
}

-(void)showError:(NSString *)errorString {
    if ([errorString  isEqual: @"password"]) {
        errorText.text = @"Please input a valid password";
    } else if ([errorString  isEqual: @"userName"]) {
        errorText.text = @"Please input a valid user name";
    } else if ([errorString  isEqual: @"signUp"]) {
        errorText.text = @"Account already exists.  Please try logging in";
    } else if ([errorString  isEqual: @"login"]) {
        errorText.text = @"Either your user name or password was incorrect.  Please try again";
    }
    //ensure the text is visible
    errorText.hidden = false;
}

-(void)keyboardWillShow:(NSNotification *)notification {
    //show our 'close' button, so the user can hide the keyboard when done editing
    closeButton.hidden = false;
    errorText.hidden = true;
}

-(void)keyboardWillHide:(NSNotification *)notification {
    //hide our 'close' button again
    closeButton.hidden = true;
}
@end
