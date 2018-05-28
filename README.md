# Overview and Business Case: 

## AccountTriggerEmpty.Trigger

A logicless trigger for Account designed to call the Account Handler Class
Only runs on After Insert and After Update

## AcctTriggerHandler.cls

A class called by the Trigger that captures the old and new values of the Accounts that were part of the Trigger
The values are checked to ensure that they are not blank and that the old and new values are different.
The Accounts that meet the criteria are then passed to the GoogleMapsCallout class.

## GoogleMapsCallout.cls

This class contains a method that calls out to the Google Maps API passing the Account Address.
It then receives the results and parses the results to get the specific address field components.
Once the components have been retrieved, either all or some of the address fields will be updated dependinig isStrictMode.

* isStrictMode = True
** will set all address fields to new values (overwrites all data) if result is ROOFTOP or APPROXIMATE

* isStrictMode = False
updates only the values that Google Maps returns 
this may produce less accurate responses as this includes RANGE_INTERPOLATED and GEOMETRIC_CENTER

https://developers.google.com/maps/documentation/geocoding/intro#Results

### Usage and Pre-reqs
* In order for this class to run, you will need to get an API Key from Google
	* https://developers.google.com/maps/documentation/geocoding/get-api-key
	* Update APIkey to your Google Maps API Key 

## Tests

Somewhere (street) GB (country)
unknown (street) Perth (city) WA (state) AU (country)
Perth (state) AUS (country)
A full local address in NY (all fields filled out but with abbreviations)
Just the state - NY
Just the country - US
Just the zip code 14534
The entire address written in the street field
Just a street name, once with a number and once with no number
Batch update