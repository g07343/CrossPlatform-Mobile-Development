package com.matthewlewis.eventbook;

import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import com.parse.DeleteCallback;
import com.parse.FindCallback;
import com.parse.GetCallback;
import com.parse.ParseACL;
import com.parse.ParseException;
import com.parse.ParseObject;
import com.parse.ParseQuery;
import com.parse.ParseUser;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView.OnItemLongClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

public class ViewActivity extends Activity{

	Context _context;
	ListView listView;
	TextView helperText;
	List<String> ids;
	List<String> events;
	List<String> names;
	List<Integer> months;
	List<Integer> days;
	List<Integer> hours;
	List<Integer> minutes;
	Timer updateTimer;
	int deleteCounter;
	ArrayAdapter<String> adapter = null;
	
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		
		//grab a reference to our app's context
		_context = this;
		
		//set our activity's view to the correct layout file
		setContentView(R.layout.activity_view);
		
		//grab instances of our interface elements
		listView = (ListView) findViewById(R.id.view_tableView);
		helperText = (TextView) findViewById(R.id.view_helperText);
		
		//by default, set the helper text to be invisible
		helperText.setVisibility(View.GONE);
		
		//grab the remote data for this user
		getData();
		
		//set our initial deleteCounter, which allows all running devices to stay in sync without
		//a 'race' condition since, our remote boolean get deleted eventually
		
		//set up a timer to poll Parse for updated data
		updateTimer = new Timer();
		updateTimer.schedule(new TimerTask() {

			@Override
			public void run() {
				// ensure we have an internet connection before making the remote data call
				
				
				//first, check remote boolean signaling if anything was updated
				
				ParseQuery<ParseObject> query = ParseQuery.getQuery("wasUpdated");
				query.findInBackground( new FindCallback<ParseObject>() {

					@Override
					public void done(List<ParseObject> objects, ParseException e) {
						//check if there is a boolean object stored for this account, if so, pull new data
						if (objects.isEmpty()) {
							//System.out.println("Data was not updated for this account");
						} else {
							deleteCounter ++;
							ParseObject booleanObject = objects.get(0);
							if (deleteCounter > 2) {
								deleteCounter = 0;
								//since the delete counter has at least been around for 
								//30 seconds, its safe to assume all currently running devices have updated so delete remote boolean
								booleanObject.deleteInBackground();
							}							
							timerRelay();
						}
					}					
				});
			}
			
		}, 0, 10000);
	}
	
	public void timerRelay() {
		System.out.println("updating data since timer found remote boolean value");
		this.runOnUiThread(updateRunnable);
	}
	
	private Runnable updateRunnable = new Runnable() {

		@Override
		public void run() {
			// update our UI here
			// grab all events that the current user has previously created (if any)
			ParseQuery<ParseObject> eventQuery = ParseQuery.getQuery("Event");
			eventQuery.findInBackground(new FindCallback<ParseObject>() {

				@Override
				public void done(List<ParseObject> objects, ParseException e) {
					// TODO Auto-generated method stub
					if (e == null) {
						System.out.println("Number of found events:  " + objects.size());
						// check number of returned items
						if (objects.size() > 0) {
							// there is at least one previously created event, so
							// display it to the user
							helperText.setVisibility(View.GONE);
							updateList(objects);
						} else {
							// no previously created events, so let the user know
							// that there is nothing to show
							helperText.setVisibility(View.VISIBLE);
							if (adapter != null) {
								events.clear();
								adapter.notifyDataSetChanged();
							}
						}
					} else {
						Log.d("EVENTQUERY", e.getMessage());
					}
				}
			});
		}
		
	};
	
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
        	updateTimer.cancel();
        	deleteCounter = 0;
        	startActivityForResult(addIntent, 1);
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
				updateTimer.cancel();
	        	deleteCounter = 0;
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
	
    @Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    	//this function runs whenever the user finishes the "Add" activity, so we make sure 
    	//to keep our listview updated
    	System.out.println("activity result runs");
		//getData();
    	
    	//reset our counter 
    	deleteCounter = 0;
    	
    	//restart our timer
    	//set up a timer to poll Parse for updated data
    			updateTimer = new Timer();
    			updateTimer.schedule(new TimerTask() {

    				@Override
    				public void run() {
    					// ensure we have an internet connection before making the remote data call
    					
    					
    					//first, check remote boolean signaling if anything was updated
    					
    					ParseQuery<ParseObject> query = ParseQuery.getQuery("wasUpdated");
    					query.findInBackground( new FindCallback<ParseObject>() {

    						@Override
    						public void done(List<ParseObject> objects, ParseException e) {
    							//check if there is a boolean object stored for this account, if so, pull new data
    							if (objects.isEmpty()) {
    								//System.out.println("Data was not updated for this account");
    							} else {
    								deleteCounter ++;
    								ParseObject booleanObject = objects.get(0);
    								if (deleteCounter > 2) {
    									deleteCounter = 0;
    									//since the delete counter has at least been around for 
    									//30 seconds, its safe to assume all currently running devices have updated so delete remote boolean
    									booleanObject.deleteInBackground();
    								}							
    								timerRelay();
    							}
    						}					
    					});
    				}
    				
    			}, 0, 10000);
    	
	}
	
	//this method updates our event listview
	@SuppressLint("DefaultLocale") public void updateList(List<ParseObject> objects) {
		//create string array to hold formatted events
		
		//events = new String[objects.size()];
		events = new ArrayList<String>();
		ids = new ArrayList<String>();
		names = new ArrayList<String>();
		months = new ArrayList<Integer>();
		days = new ArrayList<Integer>();
		hours = new ArrayList<Integer>();
		minutes = new ArrayList<Integer>();
		
		//loop through however many items we have and add to the listview
		for (int i = 0; i < objects.size(); i ++) {
			ParseObject currentEvent = objects.get(i);
			String eventName = currentEvent.getString("name");
			int eventMonth = currentEvent.getInt("month");
			int eventDay = currentEvent.getInt("day");
			int eventHour = currentEvent.getInt("hour");
			int eventMinute = currentEvent.getInt("minute");
			
			//convert our minutes to a string so we can check the length
			//this is so we can add a '0' in front if its less than 10 so it looks okay
			String convertedMinutes = String.valueOf(eventMinute);
			String fullEvent;
			if (convertedMinutes.length() == 1) {
				String paddedInt = String.format("%02d", eventMinute);
				fullEvent = eventName + ":" + "  " + eventMonth + "/" + eventDay + "  at  " + eventHour + ":" +  paddedInt;
			} else {
				fullEvent = eventName + ":" + "  " + eventMonth + "/" + eventDay + "  at  " + eventHour + ":" +  eventMinute;
			}
			events.add(i, fullEvent);
			
			//add all bits of individual data to their respective arraylists
			names.add(i, eventName);
			months.add(i, eventMonth);
			days.add(i, eventDay);
			hours.add(i, eventHour);
			minutes.add(i, eventMinute);
			
			//make sure to add the ids to our array so we can delete items if necessary
			ids.add(i, currentEvent.getObjectId());
		}
		
		//now that we have the formatted events, add to an adapter and update our listview
		adapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, events);
		listView.setAdapter(adapter);
		
		//add item click listener, so we can allow the user to edit items
		listView.setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> arg0, View arg1, int arg2,
					long arg3) {
				// grab all of the data of the object that was selected and send to "add" activity, which will also work for editing
				String eventName = names.get(arg2);
				int month = months.get(arg2);
				int day = days.get(arg2);
				int hour = hours.get(arg2);
				int minute = minutes.get(arg2);
				String eventId = ids.get(arg2);
				
				Intent editIntent = new Intent(_context, AddActivity.class);
				
				//add all data to the intent before passing
				editIntent.putExtra("name", eventName);
				editIntent.putExtra("month", month);
				editIntent.putExtra("day", day);
				editIntent.putExtra("hour", hour);
				editIntent.putExtra("minute", minute);
				editIntent.putExtra("id", eventId);
				
				updateTimer.cancel();
	        	deleteCounter = 0;
				startActivityForResult(editIntent, 1);
			}
			
		});
		
		//add longPressListener for listview items so we can allow them to be deleted
		listView.setOnItemLongClickListener(new OnItemLongClickListener() {
			@Override
			public boolean onItemLongClick(AdapterView<?> arg0, View arg1,
					final int selectedItem, long arg3) {
				// create dialog to allow the user to delete an item
				AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
				alertBuilder.setMessage("Delete the selected event?");
				alertBuilder.setCancelable(true);
				alertBuilder.setPositiveButton("Yes", new DialogInterface.OnClickListener() {
					//set up listener for our positive button 
					@Override
					public void onClick(DialogInterface dialog, int which) {
						// remove the item from the remote server according to its id
						//grab all events that the current user has previously created (if any)
						ParseQuery<ParseObject> eventQuery = ParseQuery.getQuery("Event");
						eventQuery.findInBackground(new FindCallback<ParseObject>() {
							
						//string of the particular object id to be deleted
						
						String idToDelete = ids.get(selectedItem);
							@Override
							public void done(List<ParseObject> objects, ParseException e) {
								// TODO Auto-generated method stub
								if (e == null) {
									//find the specific item we want to delete
									for (int i = 0; i < objects.size(); i ++) {
										ParseObject currentObject = objects.get(i);
										String localId = currentObject.getObjectId();
										if (localId.equals(idToDelete)) {
											currentObject.deleteEventually(new DeleteCallback() {

												@Override
												public void done(ParseException e) {
													//update our listview
													ids.remove(selectedItem);
													events.remove(selectedItem);
													adapter.notifyDataSetChanged();
													
													//reset the remote boolean object in case other devices 
													//are currently running the app
													ParseObject updateObject = new ParseObject("wasUpdated");
													updateObject.add("updated", true);
													updateObject.setACL(new ParseACL(ParseUser.getCurrentUser()));
													updateObject.saveInBackground();
													deleteCounter = 0;
													// now that the item has been deleted, update our list again
													getData();													
												}
											});
										}
									}								
								} else {
									Log.d("EVENTQUERY", e.getMessage());
								}
							}							
						});
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
				return true;
			}		
		});
	}
	
	public void getData() {
		// grab all events that the current user has previously created (if any)
		ParseQuery<ParseObject> eventQuery = ParseQuery.getQuery("Event");
		System.out.println("GET_DATA RUNS!");
		eventQuery.findInBackground(new FindCallback<ParseObject>() {
			
			@Override
			public void done(List<ParseObject> objects, ParseException e) {
				// TODO Auto-generated method stub
				if (e == null) {
					System.out.println("Number of found events:  " + objects.size());
					// check number of returned items
					if (objects.size() > 0) {
						// there is at least one previously created event, so
						// display it to the user
						helperText.setVisibility(View.GONE);
						updateList(objects);
					} else {
						// no previously created events, so let the user know
						// that there is nothing to show
						helperText.setVisibility(View.VISIBLE);
					}
				} else {
					Log.d("EVENTQUERY", e.getMessage());
				}
			}
		});
	}	
}
