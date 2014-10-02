package com.matthewlewis.eventbook;

import com.parse.ParseACL;
import com.parse.ParseObject;
import com.parse.ParseUser;

import android.app.Activity;
import android.os.Bundle;
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
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		
		setContentView(R.layout.activity_add);
		
		//grab our interface elements
		datePicker = (DatePicker) findViewById(R.id.add_date);
		timePicker = (TimePicker) findViewById(R.id.add_time);
		eventName = (EditText) findViewById(R.id.add_title);
		saveButton = (Button) findViewById(R.id.add_saveBtn);
		
		timePicker.setIs24HourView(false);
		
		//set the onClickListener for our button
		saveButton.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View arg0) {
				//grab data from all event widgets to save
				int day = datePicker.getDayOfMonth();
				int month = datePicker.getMonth() +1;
				
				
				int hour = timePicker.getCurrentHour();
				int minute = timePicker.getCurrentMinute();
				
				String name = eventName.getText().toString();
				
				System.out.println("Event is:  " + name + " on " + month + "/" + day + " at " + hour + ":" + minute);
				
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
					eventObject.saveInBackground();
					
					//return to the 'view' activity
					finish();					
				} else {
					//no name was entered, so prompt the user to pick a name
				}
				
				
			}
			
		});
	}
	
}
