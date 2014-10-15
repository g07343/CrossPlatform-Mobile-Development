package com.matthewlewis.eventbook;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

public class NetworkManager {
	public Boolean connectionStatus(Context context) {
		//set our boolean to false initially
		Boolean connected = false;
		ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
		
		//grab instance of our network state
		NetworkInfo networkInfo = cm.getActiveNetworkInfo();
		if (networkInfo != null) {
			if (networkInfo.isConnected()) {
				connected = true;
			}
		}
		
		return connected;
	}
}
