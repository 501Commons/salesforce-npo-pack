@isTest
public with sharing class Utility_TEST {

    @isTest(SeeAllData='false')
    public static void RichText_To_String_TEST() {

        List<String> returnList = Utility_RichText_To_String.richTextToString(new List<String> { '<html><header>HEADER</header><body>BODY</body><footer>FOOTER</footer></html>' });
        System.assert(returnList[0].equals('\nHEADER\nBODY\nFOOTER\n'), 'Utility_RichText_To_String::richTextToString - Not Expected String: ' + returnList[0]);
    }

    @isTest(SeeAllData='false')
    public static void PdfDownloadController_TEST() {

        Utility_PdfDownloadController controller = new Utility_PdfDownloadController();
        String pdfData = controller.getPdf();
        System.assert(!String.isBlank(pdfData), 'Utility_PdfDownloadController::getPdf - Not expecting empty string');
    }
}
