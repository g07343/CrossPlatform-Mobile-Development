package com.matthewlewis.eventbook;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;

public class ViewActivity extends Activity{

	Context _context;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		
		//grab a reference to our app's context
		_context = this;
		
		//set our activity's view to the correct layout file
		setContentView(R.layout.activity_view);
		
		//grab all events that the current user has previously created (if any)
	}
	
	@Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.view, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.menu_add) {
        	System.out.println("Add tapped!");
        	Intent addIntent = new Intent(_context, AddActivity.class);
        	startActivity(addIntent);
            return true;
        } else if (id == R.id.menu_logout) {
        	System.out.println("Logout tapped!");
        	buildAlert();
        	return true;
        }
        return super.onOptionsItemSelected(item);
    }

	@Override
	public void onBackPressed() {
		//user tapped the back button, so inform them they will return to the login screen and log them out
		buildAlert();
	}
    
	public void buildAlert() {
		//this method builds an alert dialog to inform the user they are returning to the login activity and will be logged out.
		//it's used for both the logout icon in the action bar, and if the user taps the 'back' soft key
		AlertDialog.Builder alertBuilder = new AlertDialog.Builder(this);
		alertBuilder.setMessage("Log out and return to login screen?");
		alertBuilder.setCancelable(true);
		alertBuilder.setPositiveButton("Yes", new DialogInterface.OnClickListener() {
			//set up listener for our positive button 
			@Override
			public void onClick(DialogInterface dialog, int which) {
				// ensure we set shared prefs value to keep the user from automatically being returned here
				SharedPreferences prefs = _context.getSharedPreferences("com.matthewlewis.eventbook", Context.MODE_PRIVATE);
				prefs.edit().putBoolean("keepLogin", false).apply();
				finish();
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
    
	
}
