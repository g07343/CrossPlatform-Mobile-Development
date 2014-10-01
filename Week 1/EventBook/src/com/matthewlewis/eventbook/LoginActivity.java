package com.matthewlewis.eventbook;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import com.parse.Parse;
import com.parse.ParseAnalytics;

public class LoginActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        //initialize Parse for this app and set App Id and Client Key
        Parse.initialize(this, "PCuGg9yXkx8II2tUUTtu9e1ar91dy66YXmNcel0L", "lDY9ulXXfTXXyVQrhzZihMm7FYDK4z4FsbZDBAtc");
        
        setContentView(R.layout.activity_login);
        
        
        
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
