/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 * Contributors : SKROBS (2012)
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

#import <Foundation/Foundation.h>
#import "iParapheur-Swift.h"


@class ADLResponseDossier;


@interface ADLSingletonState : NSObject

@property(strong, nonatomic) NSString *bureauCourant;
@property(strong, nonatomic) NSString *dossierCourantReference;
@property(strong, nonatomic) Dossier *dossierCourantObject;
@property(strong, nonatomic) NSString *currentPrincipalDocPath;
@property(strong, nonatomic) NSMutableDictionary *currentFilter;

+ (ADLSingletonState *)sharedSingletonState;

@end
