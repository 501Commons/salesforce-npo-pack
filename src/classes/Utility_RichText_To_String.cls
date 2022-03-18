public with sharing class Utility_RichText_To_String {
   
    @InvocableMethod
    public static List<String> richTextToString(List<String> richTextStrings) {

        System.Debug(LoggingLevel.DEBUG, 'Utility_RichText_To_String::richTextToString - richTextStrings: ' + richTextStrings);

        if (richTextStrings.size() <> 1) {
           System.Debug(LoggingLevel.ERROR, 'Utility_RichText_To_String::richTextToString - input variable richTextStrings invalid - size: ' + richTextStrings.size());
           return new List<String> { null };
        }
 
        String convertedString = richTextStrings[0].replaceAll('<[^>]*>', '\n');
        while (convertedString.containsIgnoreCase('\n\n')) {
            convertedString = convertedString.replace('\n\n', '\n');
        }
        
        return new List<String> { convertedString };
    }
}

