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

#import <Foundation/Foundation.h>
#import "iParapheur-Swift.h"


@interface ADLRestClientApi3 : NSObject

@property(nonatomic, strong) RestClient *swiftManager;


- (id)init;


- (void)getTypology:(NSString *)bureauId
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure;


- (void)getCircuit:(NSString *)dossier
           success:(void (^)(Circuit *))circuit
           failure:(void (^)(NSError *))failure;


- (void)getSignInfoForDossier:(NSString *)dossierId
                    andBureau:(NSString *)bureauId
                      success:(void (^)(SignInfoLegacy *))success
                      failure:(void (^)(NSError *))failure;

@end
