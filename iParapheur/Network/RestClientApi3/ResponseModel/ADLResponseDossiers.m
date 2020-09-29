/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#import "ADLResponseDossiers.h"
#import "StringUtils.h"


@implementation ADLResponseDossiers


+ (NSDictionary *)JSONKeyPathsByPropertyKey {

	return @{
			kRDSTotal : kRDSTotal,
			kRDSProtocol : kRDSProtocol,
			kRDSActionDemandee : kRDSActionDemandee,
			kRDSIsSent : kRDSIsSent,
			kRDSType : kRDSType,
			kRDSBureauName : kRDSBureauName,
			kRDSCreator : kRDSCreator,
			kRDSTitle : kRDSTitle,
			kRDSPendingFile : kRDSPendingFile,
			kRDSBanetteName : kRDSBanetteName,
			kRDSSkipped : kRDSSkipped,
			kRDSSousType : kRDSSousType,
			kRDSIsSignPapier : kRDSIsSignPapier,
			kRDSIsXemEnabled : kRDSIsXemEnabled,
			kRDSHasRead : kRDSHasRead,
			kRDSReadingMandatory : kRDSReadingMandatory,
			kRDSDocumentPrincipal : kRDSDocumentPrincipal,
			kRDSLocked : kRDSLocked,
			kRDSActions : kRDSActions,
			kRDSIsRead : kRDSIsRead,
			kRDSDateEmission : kRDSDateEmission,
			kRDSDateLimite : kRDSDateLimite,
			kRDSIncludeAnnexes : kRDSIncludeAnnexes,
			kRDSIdentifier : @"id"
	};
}


+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {

	// Tests

	BOOL isStringKey = [StringUtils doesArray:@[kRDSProtocol, kRDSActionDemandee, kRDSType, kRDSSousType, kRDSBureauName, kRDSCreator, kRDSIdentifier, kRDSTitle, kRDSBanetteName]
	                           containsString:key];

	BOOL isBooleanKey = [StringUtils doesArray:@[kRDSIsSent, kRDSIsSignPapier, kRDSIsXemEnabled, kRDSHasRead, kRDSReadingMandatory, kRDSLocked, kRDSIsRead, kRDSIncludeAnnexes]
	                            containsString:key];

	BOOL isIntegerKey = [StringUtils doesArray:@[kRDSTotal, kRDSPendingFile, kRDSSkipped, kRDSDateEmission, kRDSDateLimite]
	                            containsString:key];

	BOOL isDictionaryKey = [key isEqualToString:kRDSDocumentPrincipal];
	BOOL isArrayKey = [key isEqualToString:kRDSActions];

	// Return proper Transformer

	if (isStringKey)
		return [StringUtils getNullToNilValueTransformer];
	else if (isBooleanKey)
		return [StringUtils getNullToFalseValueTransformer];
	else if (isIntegerKey)
		return [StringUtils getNullToZeroValueTransformer];
	else if (isDictionaryKey)
		return [StringUtils getNullToEmptyDictionaryValueTransformer];
	else if (isArrayKey)
		return [StringUtils getNullToEmptyArrayValueTransformer];

	NSLog(@"ADLResponseDossiers, unknown parameter : %@", key);
	return nil;
}

@end
