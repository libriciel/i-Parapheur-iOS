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
#import <Foundation/Foundation.h>
#import "Mantle/MTLModel.h"
#import "Mantle/MTLJSONAdapter.h"


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
