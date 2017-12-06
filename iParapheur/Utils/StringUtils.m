/*
 * Copyright 2012-2017, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
	else if (error.code == -1011) // TODO : static value
		message = @"Erreur d'authentification";
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


+ (NSString *)decodeUrlString:(NSString *)encodedString {

	NSString *result = [encodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	result = result.stringByRemovingPercentEncoding;
	return result;
}


+ (NSData *)bytesFromHexString:(NSString *)aString; {

	NSString *theString = [[aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
	NSMutableData *data = [NSMutableData data];
	int idx;
	for (idx = 0; idx + 2 <= theString.length; idx += 2) {
		NSRange range = NSMakeRange((NSUInteger) idx, 2);
		NSString *hexStr = [theString substringWithRange:range];
		NSScanner *scanner = [NSScanner scannerWithString:hexStr];
		unsigned int intValue;
		if ([scanner scanHexInt:&intValue])
			[data appendBytes:&intValue
			           length:1];
	}
	return data;
}


+ (NSString *)actionNameForAction:(NSString *)action {
	
	return [self actionNameForAction:action
					   withPaperSign:NO];
}


+ (NSString *)actionNameForAction:(NSString *)action
					withPaperSign:(BOOL)isPaperSign {
	
	if ([action isEqualToString:@"VISA"])
		return @"Viser";
	
	else if (([action isEqualToString:@"SIGNATURE"]) && (!isPaperSign))
		return @"Signer";
	
	else if (([action isEqualToString:@"SIGNATURE"]) && (isPaperSign))
		return @"Signature papier";
	
	else if ([action isEqualToString:@"TDT"])
		return @"Envoyer au Tdt";
	
	else if ([action isEqualToString:@"MAILSEC"])
		return @"Envoyer par mail sécurisé";
	
	else if ([action isEqualToString:@"ARCHIVER"] || [action isEqualToString:@"ARCHIVAGE"])
		return @"Archiver";
	
	else if ([action isEqualToString:@"SECRETARIAT"])
		return @"Envoyer au secrétariat";
	
	else if ([action isEqualToString:@"SUPPRIMER"])
		return @"Supprimer";
	
	else if ([action isEqualToString:@"REJET"])
		return @"Rejeter";
	
	else if ([action isEqualToString:@"REMORD"])
		return @"Récupérer";
	
	return [NSString stringWithFormat:@"Non supporté : %@", action];
}


+ (NSString *)cleanupServerName:(NSString *)url {

	// Removing space
	// TODO Adrien : add special character restrictions tests ?

	url = [url stringByReplacingOccurrencesOfString:@" "
	                                     withString:@""];

	// Getting the server name
	// Regex :	- ignore everything before "://" (if exists)					^(?:.*:\/\/)*
	//			- then ignore following "m-" (if exists)						(?:m-)*
	//			- then catch every char but "/"									([^\/]*)
	//			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(?:.*:\\/\\/)*(?:m-)*([^\\/]*)(?:\\/.*)*$"
	                                                                       options:NSRegularExpressionCaseInsensitive
	                                                                         error:nil];

	NSTextCheckingResult *match = [regex firstMatchInString:url
	                                                options:0
	                                                  range:NSMakeRange(0, url.length)];

	if (match)
		url = [url substringWithRange:[match rangeAtIndex:1]];

	return url;
}


@end
