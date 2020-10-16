# Waterloo-Travel-Diary
Travel Diary iOS App for the Waterloo Public Transit Institute (work in progress)

[![](http://img.youtube.com/vi/sF-S33bOrs0/0.jpg)](http://www.youtube.com/watch?v=sF-S33bOrs0 "Travel Diary Screenshot")


# How it works

While easier to do, constantly recording a user's location using GPS drains their battery to the tune of 5-15% an hour depending on the age and model of their iPhone. The trade-off is between battery life and the accuracy of locations, which is important since the data collected is being used to determine user activities, their mode of transportation, and their route choice if walking, cycling, or taking local transit.

Based on the above trade-off, there are some scenarios where location accuracy can be reduced, namely when the user isn't moving and when they're moving very quickly (ie. on the highway or train).

There are four scenarios, each one using location tracking and motion activity tracking differently as to conserve the user's battery life. There are several functions that are used to determine when to transition from one state to another, and are shown in the state diagram below.

* activelyMoving: 10-metre location accuracy
* stopped: 100-metre location accuracy
* notMoving: location services stopped
* inFastVehicle: 1-km location accuracy

Motion activity tracking runs in all states.


![](https://github.com/EddyIonescu/Waterloo-Travel-Diary/blob/master/Waterloo%20Travel%20Diary-2.png)


# Configuration

The variables below can be configured using a remote configuration file stored in AWS S3, and which the app pulls whenever it starts. This allows you to push changes to app tracking without having to submit an app update.


**StartedTravellingDistanceMetres (Waterloo default: 250)**

Represents the radius a user needs to travel outside of until they are considered to be travelling while in the stopped state. Because GPS location accuracy is 100m in this state a radius of at least 200 metres (about a 3-minute walk) should be used.

*Used by userTravelling (stopped -> activelyMoving).*


**StartedMovingMinutes (Waterloo default: 10)**

Represents the length of time in which there had to be a non-stationary motion activity in at least half of the recentmost minutes for the user to be considered to be moving. For example, there was a non-stationary motion in the last 5 minutes or in every other minute, when the value is set to 10.

*Used by userMoving (notMoving -> stopped).*
 

**StoppedMovingStationaryMinutes (Waterloo default: 15)**

Represents the length of time in which there had to be stationary motion activity for the entire duration.

*Used by userStationary ( -> notMoving).*


**SameLocationDistanceMetres (Waterloo default: 100)**

Represents the radius a user needs to stay inside of for a certain length of time until they are considered to no longer be travelling (ie. are walking around a grocery store, school, or office). Because location accuracy is set to 10 metres in activelyMoving, a smaller radius can be used although it should be at least 50 metres.

**StopMovingSameLocationMinutes (Waterloo default: 15)**

Corresponding length of time for defaultSameLocationDistanceMetres

*Used by userNotTravelling (activelyMoving -> stopped).*


**FastSpeedKmh (Waterloo default: 80)**

Represents the minimum speed required for the user to be considered to be moving in a fast vehicle (along with the motion activity being in a vehicle).

**InVehicleOrStationaryMinutes (Waterloo default: 5)**

Corresponding length of time in which there was either in-vehicle or stationary motion for the entire duration.

*Used by userInFastVehicle (activelyMoving -> inFastVehicle).*

    
**ActivelyMovingMinutes (Waterloo default: 2)**

Represents the length of time in which only forms of active transportation (walking/cycling/running) were used in the past few minutes.

*Used by userActivelyMoving (inFastVehicle -> activelyMoving).*




