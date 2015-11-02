
#import "StringUtils.h"


@implementation StringUtils


+ (NSDictionary *)nilifyDictionaryValues:(NSDictionary *)dictionary {
	
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
	
	for (NSString* key in dictionary) {
		
		id value = dictionary[key];
		
		if ((value == NULL) || ([value isEqual:[NSNull null]]))
			[mutableDictionary setValue:nil
								 forKey:key];
		else
			[mutableDictionary setValue:dictionary[key]
								 forKey:key];
	}
	
	return mutableDictionary;
}


+ (BOOL)doesString:(NSString*)string
 containsSubString:(NSString*)substring {

	NSRange range = [string rangeOfString:substring];
	return range.length != 0;
}


+ (BOOL)doesArray:(NSArray *)array
   containsString:(NSString *)string {

	for (NSString *arrayElement in array)
		if ([string isEqualToString:arrayElement])
			return TRUE;

	return FALSE;
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


+ (MTLValueTransformer *)getNullToFalseValueTransformer {

	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == nil || inObj == [NSNull null])
			return @0;
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToNilValueTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == [NSNull null])
			return nil;
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToZeroValueTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == nil || inObj == [NSNull null])
			return @0;
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSDictionary new];
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSArray new];
		else
			return inObj;
	}];
}


@end
