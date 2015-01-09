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
#import "ADLResponseBureau.h"

@implementation ADLRestClientApi3


-(id) init {
    
    // Retrieve infos from settings
    NSString *urlSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"url_preference"];
    NSString *url = [NSString stringWithFormat:@"https://m.%@", urlSettings];
    NSString *loginSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"login_preference"];
    NSString *passwordSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"password_preference"];
    
    // Initialize AFNetworking HTTPClient
    NSURL *baseURL = [NSURL URLWithString:url];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    client.allowsInvalidSSLCertificate = YES;
    [client setAuthorizationHeaderWithUsername:loginSettings
                                      password:passwordSettings];
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    //
    // Levels
    
    RKObjectMapping *levelMapping = [RKObjectMapping mappingForClass:[ADLResponseGetLevel class]];
    [levelMapping addAttributeMappingsFromDictionary:@{@"level": @"level"}];
    
    RKResponseDescriptor *levelResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:levelMapping
                                                                                                 method:RKRequestMethodGET
                                                                                            pathPattern:nil
                                                                                                keyPath:nil
                                                                                            statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    [objectManager addResponseDescriptor:levelResponseDescriptor];
    
    //
    // Bureaux
    
    // Setup object mappings
    RKObjectMapping *bureauMapping = [RKObjectMapping mappingForClass:[ADLResponseBureau class]];
    [bureauMapping addAttributeMappingsFromDictionary:@{@"level":@"level",
                                                        @"hasSecretaire":@"hasSecretaire",
                                                        @"collectivite":@"collectivite",
                                                        @"description":@"desc",
                                                        @"en-preparation":@"enPreparation",
                                                        @"nodeRef":@"nodeRef",
                                                        @"shortName":@"shortName",
                                                        @"en-retard":@"enRetard",
                                                        @"image":@"image",
                                                        @"show_a_venir":@"showAVenir",
                                                        @"habilitation":@"habilitation",
                                                        @"a-archiver":@"aArchiver",
                                                        @"a-traiter":@"aTraiter",
                                                        @"id":@"id",
                                                        @"isSecretaire":@"isSecretaire",
                                                        @"name":@"name",
                                                        @"retournes":@"retournes",
                                                        @"dossiers-delegues":@"dossierDelegues"}];
    RKResponseDescriptor *bureauxResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:bureauMapping
                                                                                                   method:RKRequestMethodGET
                                                                                              pathPattern:nil
                                                                                                  keyPath:nil
                                                                                              statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    [objectManager addResponseDescriptor:bureauxResponseDescriptor];
    
    return self;
}


#pragma mark API calls


-(void)getApiLevel:(void (^)(NSNumber *))success
           failure:(void (^)(NSError *))failure {
    
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


-(void)getBureaux:(void (^)(NSArray *))success
          failure:(void (^)(NSError *))failure {
    
    [[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/bureaux"
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  ADLResponseBureau *testBureau = (ADLResponseBureau *) mappingResult.array[0];
                                                  NSLog(@"getBureaux size of %lu", (sizeof mappingResult.array));
                                                  success(nil);
                                              }
                                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  failure(error);
                                              }];
}




@end
