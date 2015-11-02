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
    ADLCollectivityDef* defaultDef = [ADLCollectivityDef new];
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
    NSString *url_preference = [preferences objectForKey:@"settings_server_url"];
    NSString *login_preference = [preferences objectForKey:@"settings_login"];
	
	// Démo values
	
	if (url_preference.length == 0) {
		url_preference = @"parapheur.demonstrations.adullact.org";
		login_preference = @"bma";
	}
	
    [defaultDef setHost:url_preference];
    [defaultDef setUsername:login_preference];
		
    return defaultDef;
}

@end
