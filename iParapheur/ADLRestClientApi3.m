//
//  ADLRestClientApi3.m
//  iParapheur
//
//  Created by Adrien Bricchi on 09/01/2015.
//
//

#import "ADLRestClientApi3.h"

#import "AFHTTPClient.h"
#import <RestKit.h>
#import "ADLResponseGetLevel.h"

@implementation ADLRestClientApi3


-(id) init {
    
    // Retrieve infos from settings
    NSString *url = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"url_preference"];
    url = [NSString stringWithFormat:@"https://m.%@", url];
    // NSString *loginPreference = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"login_preference"];
    
    NSLog(@"Adrien url : %@", url);
    
    // Initialize AFNetworking HTTPClient
    NSURL *baseURL = [NSURL URLWithString:url];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    client.allowsInvalidSSLCertificate = YES;
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    // Setup object mappings
    RKObjectMapping *levelMapping = [RKObjectMapping mappingForClass:[ADLResponseGetLevel class]];
    [levelMapping addAttributeMappingsFromDictionary:@{@"level": @"level"}];
    
    // Register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor =
    [RKResponseDescriptor responseDescriptorWithMapping:levelMapping
                                                 method:RKRequestMethodGET
                                            pathPattern:nil
                                                keyPath:nil
                                            statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    return self;
}


#pragma mark API calls


-(void)getApiLevel:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
    [[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/api/getApiLevel"
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  ADLResponseGetLevel *levelResponse = (ADLResponseGetLevel *) mappingResult.array[0];
                                                  success(levelResponse.level);
                                              }
                                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  failure(error);
                                              }];
}



@end
