public class AcctTriggerHandler
{
  // Store Trigger.oldMap and Trigger.newMap
  Map<Id, Account> oldAccts;
  Map<Id, Account> newAccts;

  /*
    Class constructor

    @param oldTriggerAcct
    Map between Id and Account for the old values

    @param newTriggerAcct
    Map between Id and Account for the new values
  */
  public AcctTriggerHandler(
    Map<Id, Account> oldTriggerAcct, 
    Map<Id, Account> newTriggerAcct)
  {
    oldAccts = oldTriggerAcct;
    system.debug(oldAccts);
    newAccts = newTriggerAcct;
    system.debug(newAccts);
  }
   
  /*
    Returns the equivalent to the compound BillingAddress in Salesforce.
    The method normalizes the whitespaces and removes any null values.

    @param a
    The Account for which we want the BillingAddress

    @return
    String representing the billing address
  */
  private static String getBillingAddress(Account a)
  {
    String street = a.BillingStreet;
    String city = a.BillingCity;
    String state = a.BillingState;
    String postal = a.BillingPostalCode;
    String country = a.BillingCountry;
    String addrs = street + city + state + postal + country;

    return addrs.toLowerCase().normalizeSpace().remove('null');
  }

  /*
    Called from AccountTriggerEmpty.trigger
    This method handles separating which Accounts to pass through to 
    the GoogleMapsCallout Class and update their address information
  */
  public void handleTrigger()
  {
    // to avoid indefinite loops, check if we're in future
    if (System.isFuture()) {
      return;
    }  

    // find which accounts that were passed in the trigger that have addresses 
    // that are different from what they previously were to avoid unnessary calls
    List<Account> acctList = new List<Account>();
    for (Account newAcct : newAccts.values()) {
      String newAddress = getBillingAddress(newAcct);
      if (string.IsBlank(newAddress)) {
        continue;
      }

      String oldAddress = '';   
      if (oldAccts != NULL) {
        oldAddress = getBillingAddress(oldAccts.get(newAcct.Id));
      }
      
      system.debug('oldAddress: ' + oldAddress);
      system.debug('new Address: ' + newAddress);
      if (newAddress != oldAddress) {
  		  acctList.add(newAcct);
      }

    }
    
    system.debug(acctList);
    // update relevant accounts using Google Maps API
    // Google Maps API doens't support batch address fetching, therefore we need
    // to call the API for each Account
    for (Account acct : acctList) {         
      GoogleMapsCallout.getGoogleGeo(getBillingAddress(acct), acct.id);
    } 
  }
}