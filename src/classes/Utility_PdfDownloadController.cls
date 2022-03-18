public class Utility_PdfDownloadController {

    public String getPdf() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://oppco.my.salesforce.com/sfc/p/1N000002MtLr/a/3l000000Ob2J/ALe2C26oG.M5t4nlllQfD_2BcsS3vfW6eD.UPSGirwY');
        req.setMethod('GET');                          

        // Make call
        Http client = new Http();
        HttpResponse rsp = client.send(req);

        System.debug(LoggingLevel.DEBUG, 'Body: ' + rsp.getBody());

        System.debug(LoggingLevel.DEBUG, 'Body as Blog: ' + rsp.getBodyAsBlob().toString());

        return EncodingUtil.base64Encode(rsp.getBodyAsBlob()); 
    }
}
