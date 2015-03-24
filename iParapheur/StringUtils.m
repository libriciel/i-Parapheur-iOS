
#import "StringUtils.h"
#import "AJNotificationView.h"


@implementation StringUtils


+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary {
	
	NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
	
	for (NSString* key in dictionary) {
		
		id value = [dictionary objectForKey:key];
		
		if ((value == NULL) || ([value isEqual:[NSNull null]]))
			[mutableDictionary setValue:nil
								 forKey:key];
		else
			[mutableDictionary setValue:[dictionary objectForKey:key]
								 forKey:key];
	}
	
	return mutableDictionary;
}


+ (NSString *)getErrorMessage:(NSError *)error {
	
	NSString *message = error.localizedDescription;
	
	if (error.code == kCFURLErrorNotConnectedToInternet)
		message = @"La connexion Internet a été perdue.";
	else if ( ((kCFURLErrorCannotLoadFromNetwork <= error.code) && (error.code <= kCFURLErrorSecureConnectionFailed)) || (error.code == kCFURLErrorCancelled) )
		message = @"Le serveur n'est pas valide";
	else if (error.code == kCFURLErrorUserAuthenticationRequired)
		message = @"Échec d'authentification";
	else if ((error.code == kCFURLErrorCannotFindHost) || (error.code == kCFURLErrorBadServerResponse))
		message = @"Le serveur est introuvable";
	else if (error.code == kCFURLErrorTimedOut)
		message = @"Le serveur ne répond pas dans le délai imparti";
	
	return message;
}


+ (void)logErrorMessage:(NSError *)error {
	
	UIViewController *rootController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
	[AJNotificationView showNoticeInView:[rootController view]
									type:AJNotificationTypeRed
								   title:[self getErrorMessage:error]
						 linedBackground:AJLinedBackgroundTypeStatic
							   hideAfter:2.5f];
}


+ (MTLValueTransformer *)getNullToFalseValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSNumber numberWithInteger: 0];
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToNilValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == [NSNull null])
			return nil;
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToZeroValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSNumber numberWithInt:0];
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [[NSDictionary alloc] init];
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [[NSArray alloc] init];
		else
			return inObj;
	}];
}


@end
