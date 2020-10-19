using Toybox.Math;
using Toybox.Activity;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.StringUtil;
using Toybox.Sensor;

module Data {

    enum {
        TIMER,
        DISTANCE,
        PACE,
        SPEED,
        AVERAGE_PACE,
        AVERAGE_SPEED,
        CURRENT_HEART_RATE,
        AVERAGE_HEART_RATE,
        LAP_TIMER,
        LAP_DISTANCE,
        LAP_PACE,
        LAP_SPEED,
        LAST_LAP_PACE,
        LAST_LAP_SPEED,
        LAP,
        ALTITUDE,
        CLOCK_TIME,
        BATTERY
    }

    const AVG_CHAR = StringUtil.utf8ArrayToString([0xC3,0x98]);

    const dataScreensDefault = [
                        [TIMER,DISTANCE,AVERAGE_PACE,CURRENT_HEART_RATE],
                        [LAP_TIMER,LAP_DISTANCE,LAP_PACE,LAP],
                        [SPEED,AVERAGE_SPEED,LAST_LAP_SPEED,LAP_DISTANCE]
                      ];

    const dataFieldValues = [
        TIMER,
        DISTANCE,
        PACE,
        SPEED,
        AVERAGE_PACE,
        AVERAGE_SPEED,
        CURRENT_HEART_RATE,
        AVERAGE_HEART_RATE,
        LAP_TIMER,
        LAP_DISTANCE,
        LAP_PACE,
        LAP_SPEED,
        LAST_LAP_PACE,
        LAST_LAP_SPEED,
        LAP,
        ALTITUDE,
        CLOCK_TIME,
        BATTERY];

    const dataFieldMenuLabels = [
        "Timer",
        "Dist.",
        "Pace",
        "Speed",
        "Avg\nPace",
        "Avg\nSpeed",
        "Heart\nRate",
        "Avg\nHeart\nRate",
        "Lap\nTimer",
        "Lap\nDist.",
        "Lap\nPace",
        "Lap\nSpeed",
        "Last\nLap\nPace",
        "Last\nLap\nSpeed",
        "Laps",
        "Alt",
        "Clock\nTime",
        "Bat."];

    const dataFieldLabels = [
        "Timer",
        "Distance",
        "Pace",
        "Speed",
        AVG_CHAR + " Pace",
        AVG_CHAR + " Speed",
        "Heart Rate",
        AVG_CHAR + "Heart Rate",
        "Lap Timer",
        "Lap Dist.",
        "Lap Pace",
        "Lap Speed",
        "LL Pace",
        "LL Speed",
        "Laps",
        "Altitude",
        "Clock Time",
        "Battery"];

    var dataScreens = dataScreensDefault;
    var activeDataScreens = [];

    function setDataScreens(pDataScreens) {
        dataScreens = pDataScreens;
        determineActiveDataScreens();
    }

    function getDataScreens() {
        return dataScreens;
    }

    function setDataScreen(i, dataScreen) {
        if(i < dataScreens.size()) {
            dataScreens[i] = dataScreen;
            determineActiveDataScreens();
        }
    }

    function determineActiveDataScreens() {
        activeDataScreens = [];
        for(var i=0; i < dataScreens.size(); i+=1) {
            if(dataScreens[i]!= null && dataScreens[i].size() > 0) {
                activeDataScreens.add(dataScreens[i]);
            }
        }
        Sys.println("determineActiveDataScreens: " + activeDataScreens);
    }

    function timer() {
        var data=Activity.getActivityInfo().timerTime;
        return data!=null? Data.msToTime(data) : "--";
    }

    function distance() {
        var data=Activity.getActivityInfo().elapsedDistance;
        return data!=null? (0.001*data+0.0001).format("%.2f") : "--";
    }

    function getDataFieldLabelValue(i) {
        var dataValue = null;
        switch(i) {
            case TIMER:
            	dataValue = timer();
                break;           
            case DISTANCE:
            	dataValue = distance();
                break;
            case PACE:
            	dataValue = Activity.getActivityInfo().currentSpeed;
        		dataValue = dataValue != null? Data.convertSpeedToPace(dataValue) : null;
                break;
            case SPEED:
            	dataValue = Activity.getActivityInfo().currentSpeed;
        		dataValue = dataValue != null? (3.6*dataValue).format("%.2f") : null;
                break;
            case AVERAGE_PACE:
                dataValue = Activity.getActivityInfo().averageSpeed;
        		dataValue = dataValue != null?  Data.convertSpeedToPace(dataValue) : null;	
                break;
            case AVERAGE_SPEED:
                dataValue = Activity.getActivityInfo().averageSpeed;
        		dataValue = dataValue != null?  (3.6*dataValue).format("%.2f") : null;
            	break;
            case CURRENT_HEART_RATE:
                dataValue = Activity.getActivityInfo().currentHeartRate;     
                break;
            case AVERAGE_HEART_RATE:
                dataValue = Activity.getActivityInfo().averageHeartRate;
                break;
            case LAP_TIMER:
            	if(Trace.autolapDistance > 0) {
            		dataValue = Data.msToTime(Trace.lapTime.toLong());
        		}
                break;
            case LAP_DISTANCE:
                if(Trace.autolapDistance > 0) {
            		dataValue = (0.001*Data.Trace.lapDistance).format("%.2f");
        		}
                break;
            case LAP_PACE:
                if(Trace.autolapDistance > 0 && Trace.lapTime > 0) {
            		dataValue = Data.convertSpeedToPace(1000*Trace.lapDistance/Trace.lapTime);
        		}
                break;
            case LAP_SPEED:
                if(Trace.autolapDistance > 0  && Trace.lapTime > 0) {
            		dataValue = (3600.0*Trace.lapDistance/Trace.lapTime).format("%.2f");
        		}
                break;
            case LAST_LAP_PACE:
                if(Trace.autolapDistance > 0 && Trace.lapTimeP > 0) {
            		dataValue = Data.convertSpeedToPace(1000*Trace.lapDistanceP/Trace.lapTimeP);
        		}
                break;
            case LAST_LAP_SPEED:
                if(Trace.autolapDistance > 0 && Trace.lapTimeP > 0) {
            		dataValue = (3600*Trace.lapDistanceP/Trace.lapTimeP).format("%.2f");
        		}
                break;
            case LAP:
                if(Trace.autolapDistance > 0) {
            		dataValue = Trace.lapCounter;
        		}
                break;
            case ALTITUDE:
                var dataValue = Activity.getActivityInfo().altitude;
       			dataValue = dataValue!=null? data.format("%.0f") : null;
                break;
            case CLOCK_TIME:
                dataValue = Sys.getClockTime();
        		dataValue = dataValue != null? data.hour.format("%02d") + ":" + data.min.format("%02d") + ":" + data.sec.format("%02d"): null;
                break;
            case BATTERY:
            	dataValue = Sys.getSystemStats().battery;
                break;
            default:
                break;
        }
        return [dataFieldLabels[i], dataValue];
    }

    function msToTime(ms) {
        var seconds = (ms / 1000) % 60;
        var minutes = (ms / 60000) % 60;
        var hours = ms / 3600000;

        return Lang.format("$1$:$2$:$3$", [hours, minutes.format("%02d"), seconds.format("%02d")]);
    }

    function msToTimeWithDecimals(ms) {
        var decimals = (ms % 1000) / 10;
        var seconds = (ms / 1000) % 60;
        var minutes = (ms / 60000) % 60;
        var hours = ms / 3600000;
        var string = "";

        if (hours > 0){
            string = Lang.format("$1$:$2$:$3$", [hours, minutes.format("%02d"), seconds.format("%02d")]);
        }
        else{
            string = Lang.format("$1$:$2$.$3$", [minutes.format("%02d"), seconds.format("%02d"), decimals.format("%02d")]);
        }

        return string;
    }

    function convertSpeedToPace(speed) {
        var result_min;
        var result_sec;
        var result_per;
        var conversionvalue;
        var settings = Sys.getDeviceSettings();

        result_min = 0;
        result_sec = 0;
        if( settings.paceUnits == Sys.UNIT_METRIC ) {
            result_per = "/km";
            conversionvalue = 1000.0d;
        } else {
            result_per = "/mi";
            conversionvalue = 1609.34d;
        }

        if( speed != null && speed > 0 ) {
            var secpermetre = 1.0d / speed; // speed = m/s
            result_sec = secpermetre * conversionvalue;
            result_min = result_sec / 60;
            result_min = result_min.format("%d").toNumber();
            result_sec = result_sec - ( result_min * 60 );  // Remove the exact minutes, should leave remainder seconds
        }

        //return Lang.format("$1$:$2$$3$", [result_min, result_sec.format("%02d"), result_per]);
        return Lang.format("$1$:$2$", [result_min, result_sec.format("%02d")]);
    }

    function max(x,y) {
        if(x>=y) {
            return x;
        } else {
            return y;
        }
    }

     function min(x,y) {
        if(x<y) {
            return x;
        } else {
            return y;
        }
    }
}