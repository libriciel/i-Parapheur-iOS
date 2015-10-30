//
//  ADLResponseDossier.h
//  iParapheur
//
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


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
