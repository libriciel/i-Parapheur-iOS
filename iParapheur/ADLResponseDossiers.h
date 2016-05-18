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
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


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
