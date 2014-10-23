//
//  LoginViewController.m
//  EventBook
//
//  Created by Matthew Lewis on 10/6/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "EventsViewController.h"
#import "NetworkManager.h"

@interface LoginViewController () 

@end

@implementation LoginViewController

bool rememberMe = false;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //hide our close keyboard button by default
    closeButton.hidden = true;
    
    //hide our error text by default
    errorText.hidden = true;
    errorText.numberOfLines = 3;

    //add listeners for when the keyboard appears and disappears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:)name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    
    //immediately check if there is previously saved 'remember me' value in user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //check if the grabbed bool is nill, meaning it wasn't previously stored
    if ([defaults objectForKey:@"rememberUser"] != nil) {
        //the key was found within prefs so grab it and check it
        bool savePref = [defaults boolForKey:@"rememberUser"];
        NSLog(@"bool found is prefs was:  %@", (savePref) ? @"YES" : @"NO");
        if (savePref == false) {
            [PFUser logOut];
        } else {
            //user wanted to be remembered, so make sure we have a valid user
            PFUser *currentUser = [PFUser currentUser];
            if (currentUser != nil) {
                NSLog(@"User was NOT nill");
                //previously logged in user found, so send to 'view' activity
                UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIViewController *eventView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"EventsViewController"];
                [self presentViewController:eventView animated:YES completion:nil];
            } else {
                NSLog(@"User was found to be nill...");
            }
            
        }
    } else {
        NSLog(@"KEY NOT FOUND");
    }
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
    NSUInteger nameLength = name.length;
    NSUInteger passLength = pass.length;
    
    //cast a button object to the 'sender' id so we can differentiate between the two
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0)
    {//login button tapped
        if (nameLength > 0) {
            if (passLength > 0) {
                bool isConnected = [[NetworkManager GetIntance] networkConnected];
                if (isConnected) {
                    //attempt to log in the user using the supplied credentials
                    
                    [PFUser logInWithUsernameInBackground:name password:pass block:^(PFUser *user, NSError *error) {
                        if (user) {
                            //log in successful, send to 'view' activity
                            UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            UIViewController *eventView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"EventsViewController"];
                            //clear out our password field so it doesn't retain the user's password
                            password.text = @"";
                            
                            //record the 'remember me' preference
                            
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            if ([saveToggle isOn]) {
                                [defaults setBool:true forKey:@"rememberUser"];
                            } else {
                                [defaults setBool:false forKey:@"rememberUser"];
                            }
                            [defaults synchronize];
                            //ensure our error text is invisible, in case the user logs out from the 'view' activity
                            errorText.hidden = true;
                            [self presentViewController:eventView animated:YES completion:nil];
                            
                        } else {
                            //error logging in, alert user
                            [self showError:@"login"];
                        }
                    }];
                } else {
                    //no internet connection, so give option to go into 'offline' mode
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection" message:@"You do not currently have a network connection.   Enter the app in offline mode?  NOTE:  Any data entered may not be saved!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Go offline", nil];
                    alert.tag = 27;
                    [alert show];
                }
                
            } else {
                [self showError:@"password"];
            }
        } else {
            [self showError:@"userName"];
        }
    } else if (button.tag == 1) {
        //create new button tapped
        NSLog(@"Username is:  %@ and password is: %@", name, pass);
        NSLog(@"Length of username is:  %lu", (unsigned long)nameLength);
        
        //ensure we have a network connection
        bool isConnected = [[NetworkManager GetIntance] networkConnected];
        if (isConnected) {
            //network is good
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
                            UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            UIViewController *eventView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"EventsViewController"];
                            //clear out our password field so it doesn't retain the user's password
                            password.text = @"";
                            
                            //record the 'remember me' preference
                            
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            if (saveToggle.isOn) {
                                [defaults setBool:true forKey:@"rememberUser"];
                            } else {
                                [defaults setBool:false forKey:@"rememberUser"];
                            }
                            [defaults synchronize];
                            //ensure our error text is invisible, in case the user logs out from the 'view' activity
                            errorText.hidden = true;
                            [self presentViewController:eventView animated:YES completion:nil];
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
        } else {
            //no internet connection alert user
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection" message:@"You do not currently have a network connection.  Please reconnect to the internet before attempting to create a new account." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alert show];
        }
        
        
        
    } else if (button.tag == 2) {
        //close keyboard button tapped
        [userName resignFirstResponder];
        [password resignFirstResponder];
    }
}

//this allows us to detect which choice the user selects when trying to log in with no network connection
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //ensure we are only checking the alert that displays when trying to log in
    if (alertView.tag == 27) {
        if (buttonIndex == 0) {
            NSLog(@"index was 0");
        } else if (buttonIndex == 1) {
            NSLog(@"index was 1");
            UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *eventView = [mainStoryBoard instantiateViewControllerWithIdentifier:@"EventsViewController"];
            errorText.hidden = true;
            [self presentViewController:eventView animated:YES completion:nil];
        }
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
