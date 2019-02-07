/*
 * Copyright 2012-2019, Libriciel SCOP.
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
