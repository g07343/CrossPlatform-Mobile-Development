package com.matthewlewis.eventbook;

import java.util.List;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Checkable;
import android.widget.EditText;

import com.parse.FindCallback;
import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseException;
import com.parse.ParseObject;
import com.parse.ParseQuery;
import com.parse.ParseUser;
import com.parse.SaveCallback;
import com.parse.SignUpCallback;

public class LoginActivity extends Activity {

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
        
        //set up onClick methods for our buttons
        loginBtn.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View arg0) {
				// grab our data from our fields and attempt to log in
				
				
			}
        	
        });
        
        //set up onClick method for our new user button
        newUserBtn.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				// grab the entered credentials and attempt to create a new user via Parse
				String userEmail = nameField.getText().toString();
				String password = passwordField.getText().toString();
				
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
							
						} else {
							
						} 
						
					}					
				});
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
