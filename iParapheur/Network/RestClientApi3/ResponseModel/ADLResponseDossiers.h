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
#import "Mantle/MTLModel.h"
#import "Mantle/MTLJSONAdapter.h"


static NSString *const kRDSIdentifier = @"identifier";
static NSString *const kRDSTotal = @"total";
static NSString *const kRDSProtocol = @"protocol";
static NSString *const kRDSActionDemandee = @"actionDemandee";
static NSString *const kRDSIsSent = @"isSent";
static NSString *const kRDSType = @"type";
static NSString *const kRDSBureauName = @"bureauName";
static NSString *const kRDSCreator = @"creator";
static NSString *const kRDSTitle = @"title";
static NSString *const kRDSPendingFile = @"pendingFile";
static NSString *const kRDSBanetteName = @"banetteName";
static NSString *const kRDSSkipped = @"skipped";
static NSString *const kRDSSousType = @"sousType";
static NSString *const kRDSIsSignPapier = @"isSignPapier";
static NSString *const kRDSIsXemEnabled = @"isXemEnabled";
static NSString *const kRDSHasRead = @"hasRead";
static NSString *const kRDSReadingMandatory = @"readingMandatory";
static NSString *const kRDSDocumentPrincipal = @"documentPrincipal";
static NSString *const kRDSLocked = @"locked";
static NSString *const kRDSActions = @"actions";
static NSString *const kRDSIsRead = @"isRead";
static NSString *const kRDSDateEmission = @"dateEmission";
static NSString *const kRDSDateLimite = @"dateLimite";
static NSString *const kRDSIncludeAnnexes = @"includeAnnexes";


@interface ADLResponseDossiers : MTLModel <MTLJSONSerializing>

@property(nonatomic, strong) NSNumber *total;
@property(nonatomic, strong) NSString *protocol;
@property(nonatomic, strong) NSString *actionDemandee;
@property(nonatomic) bool isSent;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *bureauName;
@property(nonatomic, strong) NSString *creator;
@property(nonatomic, strong) NSString *identifier;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSNumber *pendingFile;
@property(nonatomic, strong) NSString *banetteName;
@property(nonatomic, strong) NSNumber *skipped;
@property(nonatomic, strong) NSString *sousType;
@property(nonatomic) bool isSignPapier;
@property(nonatomic) bool isXemEnabled;
@property(nonatomic) bool hasRead;
@property(nonatomic) bool readingMandatory;
@property(nonatomic, strong) NSDictionary *documentPrincipal;
@property(nonatomic) bool locked;
@property(nonatomic, strong) NSArray *actions;
@property(nonatomic) bool isRead;
@property(nonatomic, strong) NSNumber *dateEmission;
@property(nonatomic, strong) NSNumber *dateLimite;
@property(nonatomic) bool includeAnnexes;

@end
