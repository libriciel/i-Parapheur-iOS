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
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
    NSString *url_preference = [preferences objectForKey:@"settings_server_url"];
    NSString *login_preference = [preferences objectForKey:@"settings_login"];
	
    [defaultDef setHost:url_preference];
    [defaultDef setUsername:login_preference];
		
    return defaultDef;
}

@end
