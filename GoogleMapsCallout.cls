/*
    Prior to running this class you will need to get an API Key
        https://developers.google.com/maps/documentation/geocoding/get-api-key

    For a full description of the JSON response visit:
        https://developers.google.com/maps/documentation/geocoding/intro#GeocodingResponses

    isStrictMode = True - will set all address fields to new values
        if result is ROOFTOP or APPROXIMATE
    isStrictMode = False - updates only the values that Google returns
        this may produce less accurate responses as this includes RANGE_INTERPOLATED
        and GEOMETRIC_CENTER
    For more details about these codes visit: 
        https://developers.google.com/maps/documentation/geocoding/intro#Results
*/

public class GoogleMapsCallout 
{
    // set the variables for the API callout
    Static String APIkey = '&key=';
    Static String URLEndpoint = 'https://maps.googleapis.com/maps/api/geocode/json?address=';

    Static Boolean isStrictMode = True;

    // class for setting the address fields
    class GeoProps {
        String street_number = ''; 
        String city = '';
        String state_short = '';
        String country_short = '';
        String postal_code = '';
        String street_name = '';    
    }

   /*
    Updates the values in Salesforce based on isStrictMode
    if isStrictMode is True, then all values are replaced, this could include NULL
    if isStrictMode is False, only fields with new values are replaced

    @param accountId
    The account Id of which to update in Salesforce

    @param gpObj
    The GeoProps instance that was used to store the results from Google API

   */
    private Static void updateAcctAddress(Id accountId, GeoProps gpObj) 
    {
        Account targetAccount = new Account(Id=accountId);

        if (isStrictMode) {
            targetAccount.billingStreet = gpObj.street_number + ' ' + gpObj.street_name;
            targetAccount.billingCity = gpObj.city;
            targetAccount.billingState = gpObj.state_short;
            targetAccount.billingCountry = gpObj.country_short;
            targetAccount.billingPostalCode = gpObj.postal_code;
        } else {
            if ((!String.isBlank(gpObj.street_number)) || (!String.isBlank(gpObj.street_name))) {
                targetAccount.billingStreet = gpObj.street_number + ' ' + gpObj.street_name;
                targetAccount.billingStreet.normalizeSpace();
            }
            if (!String.isBlank(gpObj.city)) {
                targetAccount.billingCity = gpObj.city;
            }
            if (!String.isBlank(gpObj.state_short)) {
                targetAccount.billingState = gpObj.state_short;
            }
            if (!String.isBlank(gpObj.country_short)) {
                targetAccount.billingCountry = gpObj.country_short;
            }
            if (!String.isBlank(gpObj.postal_code)) {
                targetAccount.billingPostalCode = gpObj.postal_code;
            }
        }    

        update targetAccount;
    }

    /*
    Creates an HTTP request to the Google Maps API.
    Receives the response from the API for the address that was passed.
    The response is then parsed to obtain the correct address fields.
    The data is then passed to the updateAcctAddress.
    */

    //future callout class to google geocode api
    @future (callout = true) 
    public static void getGoogleGeo(String addy, Id acctId) 
    {
        // encode the address passed in the parameters
        String addyEncoded = EncodingUtil.urlEncode(addy, 'UTF-8');

        // create the get request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URLEndpoint + addyEncoded + APIkey);
        system.debug(request);
        request.setMethod('GET');
        HttpResponse response;
        
        try {
            response = http.send(request);
        }
        catch (System.CalloutException e) {
            System.debug('ERROR:' + e);
            System.debug(response.getStatusCode());
            System.debug(response.getStatus());
            return;
        }

        if (response.getStatusCode() != 200) {
            system.debug('Google Maps API code != 200 ' + response.getStatusCode());
            return;
        }

        GeoProps gp = new GeoProps();
        // Check if API status was successful
        Map<String, Object> gresults = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        system.debug('results: ' + gresults.get('results'));
        system.debug('status: ' + gresults.get('status'));
        if (gresults.get('status') != 'OK') {
            system.debug('GMap API status not OK');
            return;
        }

        List<Object> gresultsList = (List<Object>)gresults.get('results');
        system.debug('gresultsList: ' + gresultsList[0]);
        Map<String, Object> addressComponents = (Map<String, Object>)gresultsList[0];
        List<Object> addressComponentsList = (List<Object>)addressComponents.get('address_components');

        if (isStrictMode == TRUE) {
            Map<String, Object> geometryList = (Map<String, Object>)addressComponents.get('geometry');
            String locationType = (String)geometryList.get('location_type');
            system.debug('print location type:' + locationType);
            // Location Type is the particular type of result produced
            // See above comments for link to Google API
            if (locationType != 'ROOFTOP' && locationType != 'APPROXIMATE') {
                return;
            }
        }

        // Loop through the Address Component to get each relevant address value
        for (Object component : addressComponentsList) {
            Map<String, Object> componentMap = (Map<String, Object>)component;
            List<Object> geoTypes = (List<Object>)componentMap.get('types');
            if (geoTypes.contains('street_number')) {
                gp.street_number = (String)componentMap.get('short_name');
            } 
            else if (geoTypes.contains('route')) {
                gp.street_name = (String)componentMap.get('short_name');      
            } 
            else if (geoTypes.contains('country')) {
                gp.country_short = (String)componentMap.get('short_name');
            }
            else if (geoTypes.contains('locality')) {
                gp.city = (String)componentMap.get('short_name');
            }
            else if (geoTypes.contains('postal_town')) {
                gp.city = (String)componentMap.get('short_name');
            }
            else if (geoTypes.contains('administrative_area_level_1')) {
                gp.state_short = (String)componentMap.get('short_name');
            }
            else if (geoTypes.contains('postal_code')) {
                gp.postal_code = (String)componentMap.get('short_name');
            }
        }

        system.debug(gp);

        // Pass id and geoprops to the updateAcctAddress function
        if (gp != NULL) {
            updateAcctAddress(acctId, gp);
        }  
    }

}


