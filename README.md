# Waterloo-Travel-Diary
Travel Diary iOS App for the Waterloo Public Transit Institute (work in progress)

[![](http://img.youtube.com/vi/sF-S33bOrs0/0.jpg)](http://www.youtube.com/watch?v=sF-S33bOrs0 "Travel Diary Screenshot")


# How it works

While easier to do, constantly recording a user's location using GPS drains their battery to the tune of 5-15% an hour depending on the age and model of their iPhone. The trade-off is between battery life and the accuracy of locations, which is important since the data collected is being used to determine user activities, their mode of transportation, and their route choice if walking, cycling, or taking local transit.

Based on the above trade-off, there are some scenarios where location accuracy can be reduced, namely when the user isn't moving and when they're moving very quickly (ie. on the highway or train).

There are four scenarios, each one using location tracking and motion activity tracking differently as to conserve the user's battery life. There are several functions that are used to determine when to transition from one state to another, and are shown in the state diagram below.

[![](https://github.com/EddyIonescu/Waterloo-Travel-Diary/blob/master/Waterloo%20Travel%20Diary.png)

# Configuration



