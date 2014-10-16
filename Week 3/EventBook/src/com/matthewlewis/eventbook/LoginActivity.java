package com.matthewlewis.eventbook;


import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Checkable;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.parse.LogInCallback;
import com.parse.Parse;
import com.parse.ParseException;
import com.parse.ParseUser;
import com.parse.SignUpCallback;

public class LoginActivity extends Activity {

TextView errorText;
Context _context;
Checkable saveCredentials;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.activity_login);
        
        //grab a reference to our app's context
        _context = this;
        
        //initialize Parse for this app and set App Id and Client Key
        Parse.initialize(this, "PCuGg9yXkx8II2tUUTtu9e1ar91dy66YXmNcel0L", "lDY9ulXXfTXXyVQrhzZihMm7FYDK4z4FsbZDBAtc");
        
        //check to see if SharedPrefs contains a value for keeping the user logged in
        SharedPreferences prefs = _context.getSharedPreferences("com.matthewlewis.eventbook", Context.MODE_PRIVATE);
        if (prefs.contains("keepLogin")) {
        	Boolean keepLogin = prefs.getBoolean("keepLogin", false);
        	if (keepLogin == false) {
        		ParseUser.logOut();
        	}
        }
        
        //check to see if the user is logged in from the app cache still
        ParseUser currentUser = ParseUser.getCurrentUser();
        if (currentUser != null) {
        	//since we were able to find the previously logged in user, we can go ahead and send them to the 'viewer' activity
        	Intent viewIntent = new Intent(_context, ViewActivity.class);
			System.out.println("Login Successful!");
			startActivity(viewIntent);
        	System.out.println("User data found!" + "  Current username is:  " + currentUser.getUsername());
        	
        } else {
        	System.out.println("No previous user data found...");
        }
        
        //grab our UI Elements that we'll need
        final EditText nameField = (EditText) findViewById(R.id.emailField);
        final EditText passwordField = (EditText) findViewById(R.id.passwordField);
        Button loginBtn = (Button) findViewById(R.id.loginButton);
        Button newUserBtn = (Button) findViewById(R.id.newUserButton);
        saveCredentials = (Checkable) findViewById(R.id.loginCheckbox);
        errorText = (TextView) findViewById(R.id.errorText);
        
        //set the errorText to not be visible by default
        errorText.setVisibility(View.GONE);
        
        //set up onClick methods for our buttons
        loginBtn.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View arg0) {
				// grab our data from our fields and attempt to log in
				final String userEmail = nameField.getText().toString();
				final String password = passwordField.getText().toString();
				
				//make sure to record whether the user wants to stay logged in
				setLoginPrefs();
				NetworkManager nm = new NetworkManager();
				boolean isConnected = nm.connectionStatus(_context);
				if (isConnected) {
					//check to ensure there is at least something in the above fields
					if (userEmail != null && userEmail.length() > 0) {
						if (password != null && password.length() > 0) {
							ParseUser.logInInBackground(userEmail, password, new LogInCallback() {

								@Override
								public void done(ParseUser user, ParseException e) {
									// check to see if the user was successfully logged in or not
									if (user != null) {
										//make sure to clear out the fields if the checkbox is left unchecked
										if (!(saveCredentials.isChecked())) {
											nameField.setText("");
											passwordField.setText("");
										}
										
										//since we have successfully logged into an account, hide the error text in case it's showing
										errorText.setVisibility(View.GONE);
										
										//we logged in, so send user to the 'view' activity
										Intent viewIntent = new Intent(_context, ViewActivity.class);
										System.out.println("Login Successful!");
										startActivity(viewIntent);
									} else {
										showError("loginFailed");
										e.printStackTrace();
									}								
								}							
							});
						} else {
							//user did not enter a password
							showError("password");
						}				
					} else {
						//user forgot to input an email address
						showError("username");
					}
				} else {
					//no network, give user the option to enter app in 'offline' mode
					//no network was detected, so let the user know
					AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
					alertBuilder.setMessage("Cannot login because you aren't connected to the internet.  Enter the app in offline mode?  NOTE:  Any data entered will not be saved!");
					alertBuilder.setCancelable(true);
					alertBuilder.setPositiveButton("Settings", new DialogInterface.OnClickListener() {
						//set up listener for our positive button 
						@Override
						public void onClick(DialogInterface dialog, int which) {
							// attempt to send the user to network settings via intent
							Intent networkIntent = new Intent(Settings.ACTION_SETTINGS);									
							startActivity(networkIntent);
						}
					});
					//set up listener for our 'no' button
					alertBuilder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
						
						@Override
						public void onClick(DialogInterface dialog, int which) {
							// cancel the dialog
							dialog.cancel();				
						}
					});
					
					//build alert and show it!
					AlertDialog logoutAlert = alertBuilder.create();
					logoutAlert.setButton(AlertDialog.BUTTON_NEUTRAL, "Go offline", new DialogInterface.OnClickListener() {

						@Override
						public void onClick(DialogInterface arg0, int arg1) {
							//let the user enter the app in offline mode without logging in
							Intent offlineIntent = new Intent(_context, ViewActivity.class);
							startActivity(offlineIntent);
						}
						
					});
					
					logoutAlert.show();
				}
								
			}        	
        });
        
        //set up onClick method for our new user button
        newUserBtn.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				// grab the entered credentials and attempt to create a new user via Parse
				final String userEmail = nameField.getText().toString();
				String password = passwordField.getText().toString();
				
				//make sure to record whether the user wants to stay logged in
				setLoginPrefs();
				
				if (userEmail != null && userEmail.length() > 0) {
					if (password != null && password.length() > 0) {
						//create a ParseUser object and set to what the user input
						ParseUser newUser = new ParseUser();
						newUser.setUsername(userEmail);
						newUser.setPassword(password);
						
						//need to ensure we have network connectivity to properly sign up a new user
						NetworkManager nm = new NetworkManager();
						Boolean isConnected = nm.connectionStatus(_context);
						
						if (isConnected) {
							//attempt to sign up the user now
							newUser.signUpInBackground(new SignUpCallback() {

								@Override
								public void done(ParseException e) {
									// check to see if we were successful
									if (e == null) {
										//now that we have created the new user, send them to the "viewer" activity
										System.out.println("User:  " + userEmail + "  was created successfully!!!");
										
										//make sure to clear out the fields if the checkbox is left unchecked
										if (!(saveCredentials.isChecked())) {
											nameField.setText("");
											passwordField.setText("");
										}
										
										//since we have successfully created an account, hide the error text in case it's showing
										errorText.setVisibility(View.GONE);
										
										//show toast to user to let them know their account was created
										Toast.makeText(getApplicationContext(), "Account created",
												   Toast.LENGTH_SHORT).show();
										
										//send user to 'viewer' activity
										Intent viewIntent = new Intent(_context, ViewActivity.class);
										System.out.println("Login Successful!");
										startActivity(viewIntent);
									} else {
										//there was an error trying to create a new user, so figure out what it is and alert user
										showError("signUp");
									} 								
								}					
							});	
						} else {
							//no network was detected, so let the user know
							AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
							alertBuilder.setMessage("Cannot create a new account because you aren't connected to the internet.  Go to Network Settings?");
							alertBuilder.setCancelable(true);
							alertBuilder.setPositiveButton("Network Manager", new DialogInterface.OnClickListener() {
								//set up listener for our positive button 
								@Override
								public void onClick(DialogInterface dialog, int which) {
									// attempt to send the user to network settings via intent
									Intent networkIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);									
									startActivity(networkIntent);
								}
							});
							//set up listener for our 'no' button
							alertBuilder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
								
								@Override
								public void onClick(DialogInterface dialog, int which) {
									// cancel the dialog
									dialog.cancel();				
								}
							});
							
							//build alert and show it!
							AlertDialog logoutAlert = alertBuilder.create();
							logoutAlert.show();
						}											
					} else {
						//no password
						showError("password");
					}	
				} else {
					showError("username");
				}				
			}      	
        });
        
        //add listener to checkbox so that we can allow the user to bypass the login screen if they choose to
        ((CompoundButton) saveCredentials).setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
			
			@Override
			public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
				// set up a boolean within sharedPreferences which will determine if the app auto logs out the user when rerun
				SharedPreferences prefs = _context.getSharedPreferences("com.matthewlewis.eventbook", Context.MODE_PRIVATE);
				if (isChecked) {
					prefs.edit().putBoolean("keepLogin", true).apply();
				} else {
					prefs.edit().putBoolean("keepLogin", false).apply();
				}
			}
		}) ;
    }

    public void setLoginPrefs() {
    	SharedPreferences prefs = _context.getSharedPreferences("com.matthewlewis.eventbook", Context.MODE_PRIVATE);
		if (saveCredentials.isChecked()) {
			prefs.edit().putBoolean("keepLogin", true).apply();
		} else {
			prefs.edit().putBoolean("keepLogin", false).apply();
		}
    }
    
    public void showError(String error) {
    	//check which type of error needs to be displayed to the user
    	if (error.equals("password")) {
    		errorText.setText("Please choose a valid password");
    	} else if (error.equals("username")) {
    		errorText.setText("Please input a valid email address");
    	} else if (error.equals("signUp")) {
    		errorText.setText("Account already exists!  Please try logging in.");
    	} else if (error.equals("loginFailed")) {
    		errorText.setText("Error logging in.  Please check your login credentials.");
    	}
    	errorText.setVisibility(View.VISIBLE);
    }
}
