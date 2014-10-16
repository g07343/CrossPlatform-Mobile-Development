package com.matthewlewis.eventbook;

import java.util.Calendar;

import com.parse.GetCallback;
import com.parse.ParseACL;
import com.parse.ParseException;
import com.parse.ParseObject;
import com.parse.ParseUser;
import com.parse.SaveCallback;
import com.parse.ParseQuery;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.DatePicker;
import android.widget.EditText;
import android.widget.TimePicker;

public class AddActivity extends Activity{

	DatePicker datePicker;
	TimePicker timePicker;
	EditText eventName;
	Button saveButton;
	Context _context;
	
	//the below vars are only set in 'edit' mode 
	String originalName;
	String originalId;
	int originalMonth;
	int originalDay;
	int originalHour;
	int originalMinute;
	
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		
		setContentView(R.layout.activity_add);
		
		//grab reference to app context
		_context = this;
		
		//grab our interface elements
		datePicker = (DatePicker) findViewById(R.id.add_date);
		timePicker = (TimePicker) findViewById(R.id.add_time);
		eventName = (EditText) findViewById(R.id.add_title);
		saveButton = (Button) findViewById(R.id.add_saveBtn);
		
		timePicker.setIs24HourView(false);
		
		//check to see if we received data from the view class, meaning the user wants to edit
		Bundle receivedData = this.getIntent().getExtras();
		if (receivedData != null && receivedData.containsKey("name")) {
			originalName = receivedData.getString("name");
			originalMonth = receivedData.getInt("month");
			originalDay = receivedData.getInt("day");
			originalHour = receivedData.getInt("hour");
			originalMinute = receivedData.getInt("minute");
			originalId = receivedData.getString("eventId");
			System.out.println("Name:  " + originalName + " Month: " + originalMonth + " Day: " + originalDay + " Hour: " + originalHour + " Minute: " + originalMinute);
			
			//default to whatever year it is currently, as we weren't ever saving this before (dangit!)
			Calendar calendar = Calendar.getInstance();
			int year = calendar.get(Calendar.YEAR);
			
			//set our original values into the entry fields 
			datePicker.init(year, originalMonth -1, originalDay, null);
			
			eventName.setText(originalName);
			
			timePicker.setCurrentHour(originalHour);
			timePicker.setCurrentMinute(originalMinute);
			
			//set up onClickListener for the save button to check what was modified and update the remote entry
			saveButton.setOnClickListener(new OnClickListener() {

				@Override
				public void onClick(View v) {
					//grab data from all event widgets to save
					final int day = datePicker.getDayOfMonth();
					final int month = datePicker.getMonth() +1;					
					final int hour = timePicker.getCurrentHour();
					final int minute = timePicker.getCurrentMinute();				
					final String name = eventName.getText().toString();
					
					NetworkManager nm = new NetworkManager();
					boolean isConnected = nm.connectionStatus(_context);
					if (isConnected) {
						// network is good, so figure out what if anything was
						// changed by user
						
						//grab the original object from parse
						ParseQuery<ParseObject> query = ParseQuery.getQuery("Event");
						
						query.getInBackground(originalId, new GetCallback<ParseObject>() {

							@Override
							public void done(ParseObject eventObject,
									ParseException e) {
								//create a simple counter to ensure at least one thing was changed
								int changeCounter = 0;
								
								// name
								if (name != null && name.length() > 0) {
									if (!(name.equals(originalName))) {
										// user edited the name so add the new one
										eventObject.put("name", name);
										changeCounter ++;
									}

									// month
									if (month != originalMonth) {
										eventObject.put("month", month);
										changeCounter ++;
									}

									// day
									if (day != originalDay) {
										eventObject.put("day", day);
										changeCounter ++;
									}

									// hour
									if (hour != originalHour) {
										eventObject.put("hour", hour);
										changeCounter ++;
									}

									// minute
									if (minute != originalMinute) {
										eventObject.put("minute", minute);
										changeCounter ++;
									}

									//check to make sure the user changed at least one thing
									//so we aren't needlessly using the network sending an 'empty' object
									if (changeCounter > 0) {
										System.out.println("Changes were made!");
										
										eventObject.saveInBackground(new SaveCallback() {

											@Override
											public void done(ParseException e) {
												//return to the 'view' activity
												finish();
											}										
										}); 
										
									} else {
										//no changes were made, alert user
										AlertDialog.Builder alertBuilder = new AlertDialog.Builder(
												_context);
										alertBuilder
												.setMessage("No changes to " + "\'" + name + "\'" +" were made.  No need to save.");
										alertBuilder.setCancelable(true);

										// set up listener for our 'okay' button
										alertBuilder.setNegativeButton("Okay",
												new DialogInterface.OnClickListener() {

													@Override
													public void onClick(
															DialogInterface dialog,
															int which) {
														// cancel the dialog
														dialog.cancel();
													}
												});

										// build alert and show it!
										AlertDialog noNameAlert = alertBuilder.create();
										noNameAlert.show();
									}						
								} else {
									// alert user to input a valid name
									// no name was entered, so prompt the user to pick a
									// name
									AlertDialog.Builder alertBuilder = new AlertDialog.Builder(
											_context);
									alertBuilder
											.setMessage("Please input a valid name");
									alertBuilder.setCancelable(true);

									// set up listener for our 'okay' button
									alertBuilder.setNegativeButton("Okay",
											new DialogInterface.OnClickListener() {

												@Override
												public void onClick(
														DialogInterface dialog,
														int which) {
													// cancel the dialog
													dialog.cancel();
												}
											});

									// build alert and show it!
									AlertDialog noNameAlert = alertBuilder.create();
									noNameAlert.show();
								}								
							}													
						});

					} else {
						// no network, alert user
						AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
						alertBuilder.setMessage("Cannot edit you event because you aren't connected to the internet.  Go to Network Settings?");
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
						AlertDialog networkAlert = alertBuilder.create();
						networkAlert.show();
					}
				}
			});
			
		} else {
			//set the onClickListener for our button to save a new event 
			saveButton.setOnClickListener(new OnClickListener() {
				
				@Override
				public void onClick(View arg0) {
					//grab data from all event widgets to save
					int day = datePicker.getDayOfMonth();
					int month = datePicker.getMonth() +1;
					
					
					int hour = timePicker.getCurrentHour();
					int minute = timePicker.getCurrentMinute();
					
					String name = eventName.getText().toString();
					
					//System.out.println("Event is:  " + name + " on " + month + "/" + day + " at " + hour + ":" + minute);
					
					NetworkManager nm = new NetworkManager();
					boolean isConnected = nm.connectionStatus(_context);
					if (isConnected) {
						// ensure the user input a name
						if (name != null && name.length() > 0) {
							//we know the user input something, so go ahead and save out the above values
							ParseObject eventObject = new ParseObject("Event");
							eventObject.put("name", name);
							eventObject.put("month", month);
							eventObject.put("day", day);
							eventObject.put("hour", hour);
							eventObject.put("minute", minute);
							
							//set the ACL property so this is only accessible to the currently logged in user
							eventObject.setACL(new ParseACL(ParseUser.getCurrentUser()));
							//save to Parse
							eventObject.saveInBackground(new SaveCallback() {

								@Override
								public void done(ParseException e) {
									//return to the 'view' activity
									finish();
								}
								
							});					
						} else {
							//no name was entered, so prompt the user to pick a name
							AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
							alertBuilder.setMessage("Please input a valid name");
							alertBuilder.setCancelable(true);
			
							//set up listener for our 'okay' button
							alertBuilder.setNegativeButton("Okay", new DialogInterface.OnClickListener() {
								
								@Override
								public void onClick(DialogInterface dialog, int which) {
									// cancel the dialog
									dialog.cancel();				
								}
							});
							
							//build alert and show it!
							AlertDialog noNameAlert = alertBuilder.create();
							noNameAlert.show();
						}					
					} else {
						//no network connection, so alert user
						AlertDialog.Builder alertBuilder = new AlertDialog.Builder(_context);
						alertBuilder.setMessage("Cannot save a new event because you aren't currently connected to the internet.  Go to Network Settings?");
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
						AlertDialog networkAlert = alertBuilder.create();
						networkAlert.show();
					}									
				}			
			});
			
		}
		
		
	}
	
	@Override
	public void onBackPressed() {
		//user tapped the back button, so inform them they will return to the login screen and log them out
		finish();
		super.finish();
	}
}
