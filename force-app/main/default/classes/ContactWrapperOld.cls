/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-18-2024
 * @last modified by  : Diego Delgado
**/
//Wrapper class for the JSON response we receive from the pipeline
public with sharing class ContactWrapperOld {

        public List<Contact> updatedContactsJson;

    /**
     * Parse method for ContactWrapper object
     * @param json 
     * @return  `ContactWrapper`
     */
    public static ContactWrapper parse(String json) {
		return (ContactWrapper) System.JSON.deserialize(json, ContactWrapper.class);
	}
}