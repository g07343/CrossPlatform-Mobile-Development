package com.matthewlewis.eventbook;

import java.util.List;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Checkable;
import android.widget.EditText;
import android.widget.TextView;

import com.parse.FindCallback;
import com.parse.LogInCallback;
import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseException;
import com.parse.ParseObject;
import com.parse.ParseQuery;
import com.parse.ParseUser;
import com.parse.SaveCallback;
import com.parse.SignUpCallback;

public class LoginActivity extends Activity {

TextView errorText;
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.activity_login);
        
        //initialize Parse for this app and set App Id and Client Key
        Parse.initialize(this, "PCuGg9yXkx8II2tUUTtu9e1ar91dy66YXmNcel0L", "lDY9ulXXfTXXyVQrhzZihMm7FYDK4z4FsbZDBAtc");
        
        //grab our UI Elements that we'll need
        final EditText nameField = (EditText) findViewById(R.id.emailField);
        final EditText passwordField = (EditText) findViewById(R.id.passwordField);
        Button loginBtn = (Button) findViewById(R.id.loginButton);
        Button newUserBtn = (Button) findViewById(R.id.newUserButton);
        Checkable saveCredentials = (Checkable) findViewById(R.id.loginCheckbox);
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
				
				//check to ensure there is at least something in the above fields
				if (userEmail != null && userEmail.length() > 0) {
					if (password != null && password.length() > 0) {
						ParseUser.logInInBackground(userEmail, password, new LogInCallback() {

							@Override
							public void done(ParseUser user, ParseException e) {
								// check to see if the user was successfully logged in or not
								if (user != null) {
									System.out.println("Login Successful!");
								} else {
									showError("loginFailed");
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
			}        	
        });
        
        //set up onClick method for our new user button
        newUserBtn.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				// grab the entered credentials and attempt to create a new user via Parse
				final String userEmail = nameField.getText().toString();
				String password = passwordField.getText().toString();
				
				if (userEmail != null && userEmail.length() > 0) {
					if (password != null && password.length() > 0) {
						//create a ParseUser object and set to what the user input
						ParseUser newUser = new ParseUser();
						newUser.setUsername(userEmail);
						newUser.setPassword(password);
						
						//attempt to sign up the user now
						newUser.signUpInBackground(new SignUpCallback() {

							@Override
							public void done(ParseException e) {
								// check to see if we were successful
								if (e == null) {
									//now that we have created the new user, send them to the "viewer" activity
									System.out.println("User:  " + userEmail + "  was created successfully!!!");
								} else {
									//there was an error trying to create a new user, so figure out what it is and alert user
									showError("signUp");
								} 								
							}					
						});
					} else {
						//no password
						showError("password");
					}	
				} else {
					showError("username");
				}				
			}      	
        });
        
        
        
        
//        //test parse to make sure it is functioning correctly and is communicating with the remote server
//        final ParseObject testObject = new ParseObject("TestObject");
//        testObject.put("isWorking", true);
//        testObject.saveInBackground(new SaveCallback() {
//
//			@Override
//			public void done(ParseException e) {
//				// TODO Auto-generated method stub
//				System.out.println("OBJECT SAVED DONE METHOD RUNS!!!");
//				String id = testObject.getObjectId();
//		        Log.d("SavedKey: ", id);
//			}
//        	
//        });
//        
//        ParseObject newObject = new ParseObject("NewObject");
//        newObject.put("location", "Orlando, FL");
//        newObject.put("age", 19);
//        newObject.put("name", "Test Name");
//        newObject.saveInBackground();
        
        
        
        ParseQuery<ParseObject> query = ParseQuery.getQuery("NewObject");
        query.findInBackground(new FindCallback<ParseObject>() {

			@Override
			public void done(List<ParseObject> objects, ParseException e) {
				// TODO Auto-generated method stub
				if (e == null) {
					//loop through saved accounts
					for (int i = 0; i < objects.size(); i ++) {
						ParseObject currentItem = objects.get(i);
						String name = currentItem.getString("name");
						System.out.println("Name found was:  " + name);
					}
					
				} else {
					System.out.println("Object not found!");
				}
			}
        	
        });
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

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.login, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
