/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */
#import "StringUtils.h"


@implementation StringUtils


+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary {
	
	NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
	
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
			return [[NSDictionary alloc] init];
		else
			return inObj;
	}];
}


+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer {
	return [MTLValueTransformer transformerUsingForwardBlock:^id(id inObj, BOOL *success, NSError *__autoreleasing *error) {
		if (inObj == nil || inObj == [NSNull null])
			return [[NSArray alloc] init];
		else
			return inObj;
	}];
}


+ (NSString *)decodeUrlString:(NSString *)encodedString {

	NSString *result = [encodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	result = result.stringByRemovingPercentEncoding;
	return result;
}

@end
