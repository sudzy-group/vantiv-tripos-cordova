/********* TriposCordova.m Cordova Plugin Implementation *******/

#import <Foundation/Foundation.h>

#import <Cordova/CDV.h>

#include <triPOSMobileSDK/triPOSMobileSDK.h>

@interface TriposCordova : CDVPlugin {
    NSString* _callbackId;
    NSOperationQueue* _queue;
    VTPConfiguration* _vtpConfiguration;
    VTP* _sharedVtp;

    VXP* _sharedVxp;
    VXPCredentials* _sharedCredentials;
    VXPApplication* _sharedApplication;
}

- (void)init:(CDVInvokedUrlCommand*)command;
- (void)sale:(CDVInvokedUrlCommand*)command;
- (void)refund:(CDVInvokedUrlCommand*)command;
- (void)creditcardReturn:(CDVInvokedUrlCommand*)command;
- (void)sendJsonFromDictionary:(NSDictionary*)dictionary;
- (void)handleNotInit;
- (NSString *) getTransactionStatusName:(VTPTransactionStatus)transactionStatus;
- (NSString *) getPaymentTypeName:(VTPPaymentType)paymentType;
@end

@implementation TriposCordova

- (void)init:(CDVInvokedUrlCommand*)command
{
    _sharedVtp = triPOSMobileSDK.sharedVtp;
    _callbackId = command.callbackId;
    
    NSLog(@"init 1 called from %@!", [self class]);
    
    NSString *mode = nil;
    mode = [command.arguments objectAtIndex:0];
    VTPApplicationMode environmentType = VTPApplicationModeTestCertification;
    if ([mode isEqualToString:@"Production"]) {
        environmentType = VTPApplicationModeProduction;
    }
    
    NSLog(@"init 2 called from %@!", [self class]);
    
    _vtpConfiguration = [[VTPConfiguration alloc] init];
    _vtpConfiguration.applicationConfiguration.mode = environmentType;
    _vtpConfiguration.applicationConfiguration.idlePrompt = @"\nSudzy POS";
    _vtpConfiguration.deviceConfiguration.deviceType = VTPDeviceTypeIngenicoRba;
    NSString *deviceType = [command.arguments objectAtIndex:5];
    if ([@"iPP350" isEqualToString:deviceType]) {
        _vtpConfiguration.deviceConfiguration.deviceType = VTPDeviceTypeIngenicoRbaTcpIp;
    }
    
    _vtpConfiguration.deviceConfiguration.isKeyedEntryAllowed = YES;
    _vtpConfiguration.deviceConfiguration.isContactlessMsdEntryAllowed = YES;
    _vtpConfiguration.deviceConfiguration.terminalId = @"00000000";
    
    NSString *tcpIpAddress = [command.arguments objectAtIndex:6];
    if (tcpIpAddress != nil) {
        _vtpConfiguration.deviceConfiguration.tcpIpConfiguration = [[VTPDeviceTcpIpConfiguration alloc] init];
        _vtpConfiguration.deviceConfiguration.tcpIpConfiguration.ipAddress = tcpIpAddress;
        _vtpConfiguration.deviceConfiguration.tcpIpConfiguration.port = 12000;
    }
    
    _vtpConfiguration.hostConfiguration.acceptorId = [command.arguments objectAtIndex:1];
    _vtpConfiguration.hostConfiguration.accountId = [command.arguments objectAtIndex:2];
    _vtpConfiguration.hostConfiguration.accountToken = [command.arguments objectAtIndex:3];
    _vtpConfiguration.hostConfiguration.applicationId = [command.arguments objectAtIndex:4];
    
    _vtpConfiguration.hostConfiguration.applicationName = @"Sudzy POS";
    _vtpConfiguration.hostConfiguration.applicationVersion = @"0.0.0.0";
    
    _vtpConfiguration.transactionConfiguration.isGiftCardAllowed = NO;
    _vtpConfiguration.transactionConfiguration.currencyCode = VTPCurrencyCodeUsd;
    _vtpConfiguration.transactionConfiguration.marketCode = VTPMarketCodeRetail;
    _vtpConfiguration.transactionConfiguration.arePartialApprovalsAllowed = YES;
    _vtpConfiguration.transactionConfiguration.areDuplicateTransactionsAllowed = YES;
    _vtpConfiguration.transactionConfiguration.isCashbackAllowed = NO;
    _vtpConfiguration.transactionConfiguration.isDebitAllowed = YES;
    _vtpConfiguration.transactionConfiguration.isEmvAllowed = YES;
    
    NSLog(@"init 3 called from %@!", [self class]);
    
    NSError* error;
    if (![_sharedVtp inititializeWithConfiguration:_vtpConfiguration error:&error])
    {
        NSDictionary* err=[NSDictionary dictionaryWithObjectsAndKeys:
                           @"onError", @"name",
                           error, @"result",  nil];
        
        [self sendJsonFromDictionary:err];
        return;
    }
    
    VTPHostConfiguration* hostConfiguration = _vtpConfiguration.hostConfiguration;
    
    _sharedCredentials = [VXPCredentials
                                   credentialsWithValues:hostConfiguration.accountId
                                   accountToken:hostConfiguration.accountToken
                                   acceptorID:hostConfiguration.acceptorId];
    
    _sharedApplication = [VXPApplication
                                   applicationWithValues:hostConfiguration.applicationId
                                   applicationName:hostConfiguration.applicationName
                                   applicationVersion:hostConfiguration.applicationVersion];
    
    VXPRequest* healthCheckRequest = [VXPRequest requestWithRequestType:VXPRequestTypeHealthCheck
                                                            credentials:_sharedCredentials
                                                            application:_sharedApplication];
    
    NSLog(@"init 4 called from %@!", [self class]);
    
    _sharedVxp = [[VXP alloc] init];
    _sharedVxp.TestCertification = _vtpConfiguration.applicationConfiguration.mode == VTPApplicationModeTestCertification;
    
    [_sharedVxp sendRequest:healthCheckRequest
             timeout: 10 * 1000
        autoReversal:YES
   completionHandler:^(VXPResponse* response)
     {
         NSLog(@"init 5 called from %@!", [self class]);
         
         NSDictionary* conf=[NSDictionary dictionaryWithObjectsAndKeys:
                             mode, @"mode", nil];
         [self sendJsonFromDictionary:conf];
     }
        errorHandler:^(NSError* error)
     {
         
         NSDictionary* err=[NSDictionary dictionaryWithObjectsAndKeys:
                            @"onError", @"name",
                            error, @"result",  nil];
         
         [self sendJsonFromDictionary:err];
         
         NSLog(@"init 6 called from %@!", [self class]);
         
     }];
}

- (void)sale:(CDVInvokedUrlCommand*)command
{
    _callbackId = command.callbackId;
    
    VTPSaleRequest* request = [[VTPSaleRequest alloc] init];
    
    request.cardholderPresentCode = VTPCardHolderPresentCodePresent;
    request.clerkNumber = @"123";
    request.convenienceFeeAmount = nil;
    request.laneNumber = @"1";
    request.referenceNumber = [command.arguments objectAtIndex:0];
    request.salesTaxAmount = nil;
    request.shiftID = @"2";
    request.ticketNumber = [command.arguments objectAtIndex:1];
    request.tipAmount = nil;
    
    NSString *amount = [command.arguments objectAtIndex:2];
    NSString *transactionAmount = [amount stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    
    request.transactionAmount = [NSDecimalNumber decimalNumberWithString:transactionAmount];
    _sharedVtp = triPOSMobileSDK.sharedVtp;
    
    if (_sharedVtp.isInitialized)
    {
        [_sharedVtp processSaleRequest:request
                     completionHandler:^(VTPSaleResponse* response)
         {
             [self saleRequestComplete:response];
         }
                          errorHandler:^(NSError* error)
         {
             [self handleError:error];
         }];
    }
    else
    {
        [self handleNotInit];
    }
}

- (void)refund:(CDVInvokedUrlCommand*)command
{
    _callbackId = command.callbackId;
    
    VTPRefundRequest* request = [[VTPRefundRequest alloc] init];
    
    request.cardholderPresentCode = VTPCardHolderPresentCodePresent;
    request.clerkNumber = @"123";
    request.convenienceFeeAmount = nil;
    request.laneNumber = @"1";
    request.referenceNumber = [command.arguments objectAtIndex:0];
    request.salesTaxAmount = nil;
    request.shiftID = @"2";
    request.ticketNumber = [command.arguments objectAtIndex:1];
    
    NSString *amount = [command.arguments objectAtIndex:2];
    NSString *transactionAmount = [amount stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    request.transactionAmount = [NSDecimalNumber decimalNumberWithString:transactionAmount];
    
    _sharedVtp = triPOSMobileSDK.sharedVtp;
    
    if (_sharedVtp.isInitialized)
    {
        [_sharedVtp processRefundRequest :request
                     completionHandler:^(VTPRefundResponse* response)
         {
             [self refundRequestComplete:response];
         }
          errorHandler:^(NSError* error)
         {
             [self handleError:error];
         }];
    }
    else
    {
        [self handleNotInit];
    }
}


- (void)creditcardReturn:(CDVInvokedUrlCommand*)command
{
    _callbackId = command.callbackId;
    
    VXPTransaction *transaction = [[VXPTransaction alloc] init];
    
    transaction.TransactionID = [command.arguments objectAtIndex:0];

    transaction.ReferenceNumber = [command.arguments objectAtIndex:1];

    NSString *amount = [command.arguments objectAtIndex:2];
    NSString *transactionAmount = [amount stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    transaction.TransactionAmount = [NSDecimalNumber decimalNumberWithString:transactionAmount];
    
    VXPTerminal *terminal = [[VXPTerminal alloc] init];
    terminal.TerminalID = @"1";
    terminal.CardPresentCode = VXPCardPresentCodePresent;
    terminal.CardholderPresentCode = VXPCardHolderPresentCodePresent;
    terminal.CVVPresenceCode = VXPCVVPresenceCodeDefault;
    terminal.TerminalCapabilityCode = VXPTerminalCapabilityCodeDefault;
    terminal.TerminalEnvironmentCode = VXPTerminalEnvironmentCodeDefault;
    terminal.MotoECICode = VXPMotoECICodeNotUsed;
    terminal.CardInputCode = VXPCardInputCodeMagstripeRead;
    
    VXPRequest* creditCardReturnRequest = [VXPRequest requestWithRequestType:VXPRequestTypeCreditCardReturn
                         credentials:_sharedCredentials
                         application:_sharedApplication];
    creditCardReturnRequest.Transaction = transaction;
    creditCardReturnRequest.Terminal = terminal;
    
    [_sharedVxp sendRequest:creditCardReturnRequest
             timeout:10000
        autoReversal:YES
   completionHandler:^(VXPResponse* response)
     {
         [self handleReturnResponse:response];
     }
        errorHandler:^(NSError* error)
     {
         [self handleError:error];
     }];
}



-(void)sendJsonFromDictionary:(NSDictionary*)dictionary {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:result callbackId:self->_callbackId];
}

- (void)saleRequestComplete:(VTPSaleResponse*)response
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateString = [dateFormatter stringFromDate:response.transactionDateTime];
    
    NSString *transactionStatus = [self getTransactionStatusName:response.transactionStatus];
    NSString *transactionId = response.host.transactionID;
    
    NSDictionary *responseArray = [NSDictionary dictionaryWithObjectsAndKeys:
                                   transactionStatus, @"transactionStatus",
                                   transactionId ? transactionId : @"<nil>", @"transactionId",
                                   response.wasProcessedOnline ? @"YES" : @"NO", @"wasProcessedOnline",
                                   response.referenceNumber, @"referenceNumber",
                                   dateString ? dateString : @"<nil>", @"transactionDateTime",
                                   [NSString stringWithFormat:@"%@", response.approvedAmount], @"approvedAmount",
                                   response.cashbackAmount ? [NSString stringWithFormat:@"%@", response.cashbackAmount] : @"<nil>", @"cashbackAmount",
                                   response.tipAmount ? [NSString stringWithFormat:@"%@", response.tipAmount] : @"<nil>", @"tipAmount",
                                   response.balanceAmount ? [NSString stringWithFormat:@"%@", response.balanceAmount] : @"<nil>", @"balanceAmount", nil];
    
    [self sendJsonFromDictionary:responseArray];
}


- (void)refundRequestComplete:(VTPRefundResponse*)response
{

    NSString* transactionStatus = [self getTransactionStatusName:response.transactionStatus];
    
    NSString* paymentType = [self getPaymentTypeName:response.paymentType];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateString = [dateFormatter stringFromDate:response.transactionDateTime];
    
    NSString *transactionId = response.host.transactionID;
    
    NSDictionary *responseArray = [NSDictionary dictionaryWithObjectsAndKeys:
                                   transactionStatus, @"transactionStatus",
                                   paymentType, @"paymentType",
                                    [NSString stringWithFormat:@"%@", response.referenceNumber], @"referenceNumber",
                                   transactionId ? transactionId : @"<nil>", @"transactionId",
                                   dateString ? dateString : @"<nil>", @"transactionDateTime", nil];
    
    [self sendJsonFromDictionary:responseArray];
}

- (void)handleReturnResponse:(VXPResponse*) response
{
    NSDictionary *responseArray = [NSDictionary dictionaryWithObjectsAndKeys:
                                   response.Transaction.TransactionStatus, @"transactionStatus",
                                   response.Transaction.TransactionID, @"transactionId",
                                   response.Transaction.ApprovedAmount, @"approvedAmount",
                                   response.Transaction.ReferenceNumber, @"referenceNumber", nil];
    
    [self sendJsonFromDictionary:responseArray];
}


- (void)handleError:(NSError*)error
{
    NSDictionary *responseArray = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%ld", (long)error.code], @"Error Code", error.localizedDescription, @"Error Localized Description", nil];
    
    [self sendJsonFromDictionary:responseArray];
}

- (void)handleNotInit
{
    NSDictionary *responseArray = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"0", @"Error Code", @"Device not initialized", @"Error Localized Description", nil];
    
    [self sendJsonFromDictionary:responseArray];
}

- (NSString *) getTransactionStatusName:(VTPTransactionStatus)transactionStatus
{
    switch (transactionStatus)
    {
        case VTPTransactionStatusApproved:
            return @"Approved";
        case VTPTransactionStatusDeclined:
            return @"Declined";
        case VTPTransactionStatusNeedsToBeReversed:
            return @"Needs to be Reversed";
        case VTPTransactionStatusUnknown:
        default:
            return @"Unknown";
    }
}

- (NSString *) getPaymentTypeName:(VTPPaymentType)paymentType
{
    switch (paymentType)
    {
        case VTPPaymentTypeCredit:
            return @"Credit";
        case VTPPaymentTypeDebit:
            return @"Debit";
        case VTPPaymentTypeUnknown:
        default:
            return @"Unknown";
    }
}

@end

