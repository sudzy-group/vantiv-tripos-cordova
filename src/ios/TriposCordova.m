/********* TriposCordova.m Cordova Plugin Implementation *******/

#import <Foundation/Foundation.h>

#import <Cordova/CDV.h>

#include <triPOSMobileSDK/triPOSMobileSDK.h>

@interface TriposCordova : CDVPlugin {
    NSString* _callbackId;
    NSOperationQueue* _queue;
    VTPConfiguration* _vtpConfiguration;
    VTP* _sharedVtp;
}

- (void)init:(CDVInvokedUrlCommand*)command;
- (void)sale:(CDVInvokedUrlCommand*)command;
- (void)refund:(CDVInvokedUrlCommand*)command;
- (void)sendJsonFromDictionary:(NSDictionary*)dictionary;
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
    _vtpConfiguration.deviceConfiguration.isKeyedEntryAllowed = YES;
    _vtpConfiguration.deviceConfiguration.isContactlessMsdEntryAllowed = YES;
    _vtpConfiguration.deviceConfiguration.terminalId = @"00000000";
    
    _vtpConfiguration.hostConfiguration.acceptorId = [command.arguments objectAtIndex:1];
    _vtpConfiguration.hostConfiguration.accountId = [command.arguments objectAtIndex:2];
    _vtpConfiguration.hostConfiguration.accountToken = [command.arguments objectAtIndex:3];
    _vtpConfiguration.hostConfiguration.applicationId = [command.arguments objectAtIndex:4];
    
    _vtpConfiguration.hostConfiguration.applicationName = @"Sudzy POS";
    _vtpConfiguration.hostConfiguration.applicationVersion = @"0.0.0.0";
    _vtpConfiguration.hostConfiguration.storeCardID = [command.arguments objectAtIndex:5];
    _vtpConfiguration.hostConfiguration.storeCardPassword = [command.arguments objectAtIndex:6];
    
    _vtpConfiguration.transactionConfiguration.isGiftCardAllowed = NO;
    _vtpConfiguration.transactionConfiguration.currencyCode = VTPCurrencyCodeUsd;
    _vtpConfiguration.transactionConfiguration.marketCode = VTPMarketCodeRetail;
    _vtpConfiguration.transactionConfiguration.arePartialApprovalsAllowed = YES;
    _vtpConfiguration.transactionConfiguration.areDuplicateTransactionsAllowed = YES;
    _vtpConfiguration.transactionConfiguration.isCashbackAllowed = NO;
    _vtpConfiguration.transactionConfiguration.isDebitAllowed = YES;
    _vtpConfiguration.transactionConfiguration.isEmvAllowed = YES;
    
    NSError* error;
    if (![_sharedVtp inititializeWithConfiguration:_vtpConfiguration error:&error])
    {
        NSDictionary* err=[NSDictionary dictionaryWithObjectsAndKeys:
                           @"onError", @"name",
                           error, @"result",  nil];
        
        [self sendJsonFromDictionary:err];
        return;
    }

    
    
    
    NSLog(@"init 3 called from %@!", [self class]);
    
    VTPHostConfiguration* hostConfiguration = _vtpConfiguration.hostConfiguration;
    
    VXPCredentials* credentials = [VXPCredentials
                                   credentialsWithValues:hostConfiguration.accountId
                                   accountToken:hostConfiguration.accountToken
                                   acceptorID:hostConfiguration.acceptorId];
    
    VXPApplication* application = [VXPApplication
                                   applicationWithValues:hostConfiguration.applicationId
                                   applicationName:hostConfiguration.applicationName
                                   applicationVersion:hostConfiguration.applicationVersion];
    
    VXPRequest* healthCheckRequest = [VXPRequest requestWithRequestType:VXPRequestTypeHealthCheck
                                                            credentials:credentials
                                                            application:application];
    
    NSLog(@"init 4 called from %@!", [self class]);
    
    VXP* vxp = [[VXP alloc] init];
    vxp.TestCertification = _vtpConfiguration.applicationConfiguration.mode == VTPApplicationModeTestCertification;
    
    [vxp sendRequest:healthCheckRequest
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

}


- (void)refund:(CDVInvokedUrlCommand*)command
{
    
}

-(void)sendJsonFromDictionary:(NSDictionary*)dictionary {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:result callbackId:self->_callbackId];
}

@end
