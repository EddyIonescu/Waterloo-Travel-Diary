# Waterloo-Travel-Diary
Travel Diary iOS App for the Waterloo Public Transit Institute. It uses a write-only S3 bucket for storing the data obtained. It also allows customizing the thresholds used to transitions between different states as to preserve battery life, with a greater amount of flexibility given than any other background location tracking library out there.

[![](http://img.youtube.com/vi/sF-S33bOrs0/0.jpg)](http://www.youtube.com/watch?v=sF-S33bOrs0 "Travel Diary Screenshot")


# How it works

While easier to do, constantly recording a user's location using GPS drains their battery to the tune of 5-15% an hour depending on the age and model of their iPhone. The trade-off is between battery life and the accuracy of locations, which is important since the data collected is being used to determine user activities, their mode of transportation, and their route choice if walking, cycling, or taking local transit.

Based on the above trade-off, there are some scenarios where location accuracy can be reduced, namely when the user isn't moving and when they're moving very quickly (ie. on the highway or train).

There are four scenarios, each one using location tracking and motion activity tracking differently as to conserve the user's battery life. There are several functions that are used to determine when to transition from one state to another, and are shown in the state diagram below.

* activelyMoving: 10-metre location accuracy
* stopped: 100-metre location accuracy
* notMoving: 3-km location accuracy
* inFastVehicle: 1-km location accuracy

Motion activity tracking runs in all states. Note that location tracking can't be entirely stopped as it then it can no longer be restarted (unless the Region Monitoring service is used, which has an accuracy of at least 2km and may take a while to invoke).


![](https://github.com/EddyIonescu/Waterloo-Travel-Diary/blob/master/Waterloo%20Travel%20Diary-2.png)


# Configuration

The variables below can be configured using a remote configuration file stored in AWS S3, and which the app pulls whenever it starts. This allows you to push changes to app tracking without having to submit an app update.


**StartedTravellingDistanceMetres (Waterloo default: 250)**

Represents the radius a user needs to travel outside of until they are considered to be travelling while in the stopped state. Because GPS location accuracy is 100m in this state a radius of at least 200 metres (about a 3-minute walk) should be used.

*Used by userTravelling (stopped -> activelyMoving).*
 

**StoppedMovingStationarySeconds (Waterloo default: 600)**

Represents the length of time in which there had to be stationary motion activity for the entire duration.

*Used by userStationary ( -> notMoving).*


**SameLocationDistanceMetres (Waterloo default: 100)**

Represents the radius a user needs to stay inside of for a certain length of time until they are considered to no longer be travelling (ie. are walking around a grocery store, school, or office). Because location accuracy is set to 10 metres in activelyMoving, a smaller radius can be used although it should be at least 50 metres.

**StopMovingSameLocationSeconds (Waterloo default: 900)**

Corresponding length of time for defaultSameLocationDistanceMetres

*Used by userNotTravelling (activelyMoving -> stopped).*


**FastSpeedKmh (Waterloo default: 80)**

Represents the minimum speed required for the user to be considered to be moving in a fast vehicle (along with the motion activity being in a vehicle).

**InVehicleOrStationarySeconds (Waterloo default: 300)**

Corresponding length of time in which there was either in-vehicle or stationary motion for the entire duration.

*Used by userInFastVehicle (activelyMoving -> inFastVehicle).*

    
**ActivelyMovingSeconds (Waterloo default: 20)**

Represents the length of time in which only forms of active transportation (walking/cycling/running) were used in the past few minutes.
This value should be long enough to exclude someone picking up their phone but short enough to invoke as it requires someone to move continously.

*Used by userActivelyMoving (inFastVehicle -> activelyMoving and notMoving -> stopped).*




