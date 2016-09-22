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
#import "ADLAPIHelper.h"
#import "iParapheur-Swift.h"


@implementation ADLAPIHelper


+ (NSString *)actionNameForAction:(NSString *)action {

	return [self actionNameForAction:action
	                   withPaperSign:NO];
}


+ (NSString *)actionNameForAction:(NSString *)action
                    withPaperSign:(BOOL)isPaperSign {

	if ([action isEqualToString:@"VISER"] || [action isEqualToString:@"VISA"])
		return @"Viser";

	else if (([action isEqualToString:@"SIGNER"] || [action isEqualToString:@"SIGNATURE"]) && (!isPaperSign))
		return @"Signer";

	else if (([action isEqualToString:@"SIGNER"] || [action isEqualToString:@"SIGNATURE"]) && (isPaperSign))
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

	else if ([action isEqualToString:@"REJETER"])
		return @"Rejeter";

	else if ([action isEqualToString:@"REMORD"])
		return @"Récupérer";

	return [NSString stringWithFormat:@"unknown : %@", action];
}


+ (NSArray *)actionsForADLResponseDossier:(Dossier *)dossier {

	NSMutableArray *actions = [NSMutableArray new];
	NSArray *returnedActions = dossier.unwrappedDocuments;
	NSString *actionDemandee = dossier.unwrappedActionDemandee;

	if ([returnedActions containsObject:actionDemandee]) {
		if ([actionDemandee isEqualToString:@"ARCHIVAGE"])
			[actions addObject:@"ARCHIVER"];

		else if ([actionDemandee isEqualToString:@"SIGNATURE"])
			[actions addObject:@"SIGNER"];

		else if ([actionDemandee isEqualToString:@"SUPPRESSION"])
			[actions addObject:@"SUPPRIMER"];

		else if ([actionDemandee isEqualToString:@"REJET"])
			[actions addObject:@"REJETER"];

		else if ([actionDemandee isEqualToString:@"REMORD"])
			[actions addObject:@"REMORD"];

		else if ([actionDemandee isEqualToString:@"SECRETARIAT"])
			[actions addObject:@"SECRETARIAT"];

		else if ([actionDemandee isEqualToString:@"VISA"])
			[actions addObject:@"VISER"];

		else if ([actionDemandee isEqualToString:@"TDT"])
			[actions addObject:@"TDT"];

		else if ([actionDemandee isEqualToString:@"MAILSEC"])
			[actions addObject:@"MAILSEC"];
	}

	return [NSArray arrayWithArray:actions];
}


+ (NSArray *)actionsForDossier:(NSDictionary *)dossier {

	NSMutableArray *actions = [NSMutableArray new];

	NSDictionary *returnedActions = dossier[@"actions"];
	NSString *actionDemandee = dossier[@"actionDemandee"];

	for (NSString *action in returnedActions.allKeys) {
		BOOL isActionEnabled = [returnedActions[action] boolValue];

		if (isActionEnabled) {
			if ([action isEqualToString:@"archive"]) {
				if ([actionDemandee isEqualToString:@"ARCHIVAGE"]) {
					[actions addObject:@"ARCHIVER"];
				}
			}
			else if ([action isEqualToString:@"delete"]) {
				[actions addObject:@"SUPPRIMER"];
			}
			else if ([action isEqualToString:@"reject"]) {
				[actions addObject:@"REJETER"];
			}
			else if ([action isEqualToString:@"remorse"]) {
				[actions addObject:@"REMORD"];
			}
			else if ([action isEqualToString:@"secretary"]) {
				[actions addObject:@"SECRETARIAT"];
			}
			else if ([action isEqualToString:@"sign"]) {
				if ([actionDemandee isEqualToString:@"SIGNATURE"]) {
					[actions addObject:@"SIGNER"];
				}
				else if ([actionDemandee isEqualToString:@"VISA"]) {
					[actions addObject:@"VISER"];
				}
				else if ([actionDemandee isEqualToString:@"TDT"]) {
					[actions addObject:@"TDT"];
				}
				else if ([actionDemandee isEqualToString:@"MAILSEC"]) {
					[actions addObject:@"MAILSEC"];
				}
			}
		}
	}

	return [NSArray arrayWithArray:actions];
}


@end
