//
//  ADLCollectivityDef.m
//  MGSplitView
//
//

#import "ADLCollectivityDef.h"

@implementation ADLCollectivityDef
@synthesize host;
@synthesize username;


+(ADLCollectivityDef*) copyDefaultCollectity {
    ADLCollectivityDef* defaultDef = [[ADLCollectivityDef alloc] init];
    
    NSString *url_preference = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_server_url"];
    NSString *login_preference = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_login"];
    
    [defaultDef setHost:url_preference];
    [defaultDef setUsername:login_preference];
    
    return defaultDef;
}

@end
