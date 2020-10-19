using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Attention as Att;
using Toybox.ActivityRecording;
using Toybox.Sensor;

using Trace;

var messageReceived = false;

var mailMethod;
var phoneMethod;
var crashOnMessage = false;
var trackView;
var dataView;
var lapView;
var viewDelegate;
var device = "generic";
var session = null;
var activityType = ActivityRecording.SPORT_RUNNING;

var doForcedUpdate = false;

var trackViewPeriod = 1;
var dataViewPeriod = 1;
var lapViewPeriod = 10;

var track = null;
var trackHeaders = [];
var maxNoTracks = 4;

class WormNavApp extends Application.AppBase {
    
    var trackViewCounter = 0;
    var dataViewCounter = 0;
    var lapViewCounter = 0;
    
    var appTimer;
	var appTimerTicks = 0;
	var vibrateData = [new Att.VibeProfile(  50, 250 )];
    
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("onStart");

        // start page is map
        mode=TRACK_MODE;
        
        device = WatchUi.loadResource(Rez.Strings.device);
        System.println("Device: " + device);
        
        //  get track headers
        trackHeaders = Application.getApp().getProperty("trackHeaders");
        
        if(trackHeaders != null && trackHeaders.size()>0 ) {
            System.println("Load track headers of size: " + trackHeaders.size());
            var trackHeader = trackHeaders[trackHeaders.size()-1];
            var data= Application.getApp().getProperty(getTrackId(trackHeader));
            if(data!=null) {
                System.println("Load data from property store with header:" + trackHeader);
                track = new TrackModel(data);    
            }
            else {
                // inconsistent state -> remove track header
                trackHeaders.remove(trackHeader);
                System.println("No track found for id:" + getTrackId(trackHeader));                        
            }
        }
        else if(trackHeaders == null) {
            // handle legacy case that property does not exist
            trackHeaders = [];       
            var data= Application.getApp().getProperty("trackData");
            if(data!=null) {
                // create new track
                System.println("Load data from property store (legacy)");
                track = new TrackModel(data);                
                System.println("Created track from property store (legacy!");
                var trackHeader = Time.now().value() + "::" + track.name;
                trackHeaders = [];
                trackHeaders.add(trackHeader);
                Application.getApp().setProperty("trackHeaders", trackHeaders);
                Application.getApp().deleteProperty("trackData");
                Application.getApp().setProperty(getTrackId(trackHeader),data);
                System.println("Created track header with id:" + getTrackId(trackHeader));
            }
        }
            
        if(Application.getApp().getProperty("northHeading")!=null) {
            Transform.northHeading=Application.getApp().getProperty("northHeading");
        }

        if(Application.getApp().getProperty("centerMap")!=null) {
            Transform.centerMap=Application.getApp().getProperty("centerMap");
        }

        if(Application.getApp().getProperty("autolapDistance")!=null) {
            Trace.autolapDistance = Application.getApp().getProperty("autolapDistance");
        }

        if(Application.getApp().getProperty("breadCrumbDist")!=null) {
            Trace.breadCrumbDist = Application.getApp().getProperty("breadCrumbDist");
        }

        if(Application.getApp().getProperty("dataScreens")!=null) {
            Data.setDataScreens(Application.getApp().getProperty("dataScreens"));
        } else {
            Data.setDataScreens(Data.dataScreensDefault);
        }

        if(Application.getApp().getProperty("activityType")!=null) {
            activityType = Application.getApp().getProperty("activityType");
        }
        
        if(Application.getApp().getProperty("trackViewPeriod")!=null) {
            trackViewPeriod = Application.getApp().getProperty("trackViewPeriod");
        }
        
        if(Application.getApp().getProperty("dataViewPeriod")!=null) {
            dataViewPeriod = Application.getApp().getProperty("dataViewPeriod");
        }
        
        if(Application.getApp().getProperty("lapViewPeriod")!=null) {
            lapViewPeriod = Application.getApp().getProperty("lapViewPeriod");
        }

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
		// explicit enablement of heart rate sensor seems to be required to detect an external HRM
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        
        // timer is used for data fields and auto lap
        appTimer = new Timer.Timer();
        appTimer.start(method(:onTimer), 1000, true);
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    // Return the initial view of your application here
    function getInitialView() {
        trackView = new TrackView();
        if(track!= null) {
            trackView.isNewTrack=true;
        }
        viewDelegate = new WormNavDelegate();
        phoneMethod = method(:onMessage);
        if(Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(phoneMethod);
        } else {
            Communications.setMailboxListener(mailMethod);
        }
        return [trackView, viewDelegate];
    }

    function onMessage(msg) {
        System.println("onMessage(msg)");
        try {
            messageReceived = true;
            mode=TRACK_MODE;
            track = new TrackModel(msg.data);
            var trackHeader = (Time.now().value() + "::" + track.name);            
            if(trackHeaders.size() == maxNoTracks) {
                trackHeaders = trackHeaders.slice(1,null);    
            }
            trackHeaders.add(trackHeader);
            System.println("trackHeaders: " + trackHeaders.toString());        
            Application.getApp().setProperty("trackHeaders", trackHeaders);
            Application.getApp().setProperty(getTrackId(trackHeader), msg.data);           
            $.trackView.isNewTrack=true;
            WatchUi.requestUpdate();
        }
        catch( ex ) {
            System.println(ex.getErrorMessage());
            track=null;
            System.exit();
        }
    }

    function onPosition(info) {
    	Trace.newLatLonPosition(info.position.toRadians()[0].toFloat(),info.position.toRadians()[1].toFloat());
    }

	// handles screen updates
    function onTimer() {
    	appTimerTicks += 1;

        if(lapViewCounter == 0 && Trace.isAutolap(false)) {
            lapViewCounter = 1;
        }

        // in lapViewMode
        if(lapViewCounter>0) {
            if(lapView == null) {
                lapView = new LapView();
            }
            if(lapViewCounter==1) {
                WatchUi.pushView(lapView, viewDelegate, WatchUi.SLIDE_IMMEDIATE);
            }
            if(lapViewCounter==2) {
                if (Attention has :vibrate) {
                    Att.vibrate( vibrateData );
                }
                if (Attention has :playTone) {
                    Attention.playTone(Attention.TONE_LAP );
                }
            }
            lapViewCounter++;

            if(lapViewCounter==lapViewPeriod) {
                lapViewCounter = 0;
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            }
        }
        else if($.mode==TRACK_MODE)  {
        	if(trackViewCounter %  trackViewPeriod == 0 || doForcedUpdate) {
                WatchUi.requestUpdate();
        	}
        	if(doForcedUpdate) {
                doForcedUpdate	= false;
                trackViewCounter = 0;
        	}
        	else {
                trackViewCounter += 1;	
        	}
       	}
        else if($.mode==DATA_MODE) {
        	if(dataViewCounter %  dataViewPeriod == 0 || doForcedUpdate) {
                WatchUi.requestUpdate();
        	}
        	if(doForcedUpdate) {
                doForcedUpdate	= false;
                dataViewCounter = 0;
        	}
        	else {
                dataViewCounter += 1;	
        	}
        }         
    }
    
    function getTrackId(header) {
        var i = header.find("::");
        if (i != null) {
            return header.substring(0,i);    
        }
        else {
            return null;
        }        
    }
    
}