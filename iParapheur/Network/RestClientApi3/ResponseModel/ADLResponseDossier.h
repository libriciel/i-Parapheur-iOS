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
#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>


static NSString *const kRDTitle = @"title";
static NSString *const kRDNomTdT = @"nomTdT";
static NSString *const kRDIncludeAnnexes = @"includeAnnexes";
static NSString *const kRDLocked = @"locked";
static NSString *const kRDReadingMandatory = @"readingMandatory";
static NSString *const kRDDateEmission = @"dateEmission";
static NSString *const kRDVisibility = @"visibility";
static NSString *const kRDIsRead = @"isRead";
static NSString *const kRDActionDemandee = @"actionDemandee";
static NSString *const kRDStatus = @"status";
static NSString *const kRDDocuments = @"documents";
static NSString *const kRDIdentifier = @"identifier";
static NSString *const kRDIsSignPapier = @"isSignPapier";
static NSString *const kRDDateLimite = @"dateLimite";
static NSString *const kRDHasRead = @"hasRead";
static NSString *const kRDIsXemEnabled = @"isXemEnabled";
static NSString *const kRDActions = @"actions";
static NSString *const kRDBanetteName = @"banetteName";
static NSString *const kRDType = @"type";
static NSString *const kRDCanAdd = @"canAdd";
static NSString *const kRDProtocole = @"protocole";
static NSString *const kRDMetadatas = @"metadatas";
static NSString *const kRDXPathSignature = @"xPathSignature";
static NSString *const kRDSousType = @"sousType";
static NSString *const kRDBureauName = @"bureauName";
static NSString *const kRDIsSent = @"isSent";


@interface ADLResponseDossier : MTLModel <MTLJSONSerializing>

@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *nomTdT;
@property(nonatomic) bool includeAnnexes;
@property(nonatomic) bool locked;
@property(nonatomic) bool readingMandatory;
@property(nonatomic, strong) NSNumber *dateEmission;
@property(nonatomic, strong) NSString *visibility;
@property(nonatomic) bool isRead;
@property(nonatomic, strong) NSString *actionDemandee;
@property(nonatomic, strong) NSString *status;
@property(nonatomic, strong) NSArray *documents;
@property(nonatomic, strong) NSString *identifier;
@property(nonatomic) bool isSignPapier;
@property(nonatomic, strong) NSNumber *dateLimite;
@property(nonatomic) bool hasRead;
@property(nonatomic) bool isXemEnabled;
@property(nonatomic, strong) NSArray *actions;
@property(nonatomic, strong) NSString *banetteName;
@property(nonatomic, strong) NSString *type;
@property(nonatomic) bool canAdd;
@property(nonatomic, strong) NSString *protocole;
@property(nonatomic, strong) NSDictionary *metadatas;
@property(nonatomic, strong) NSString *xPathSignature;
@property(nonatomic, strong) NSString *sousType;
@property(nonatomic, strong) NSString *bureauName;
@property(nonatomic) bool isSent;

@end
