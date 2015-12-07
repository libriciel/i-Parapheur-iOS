
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


static NSString *const kBLevel = @"level";
static NSString *const kBHasSecretaire = @"hasSecretaire";
static NSString *const kBCollectivite = @"collectivite";
static NSString *const kBDesc = @"desc";
static NSString *const kBEnPreparation = @"enPreparation";
static NSString *const kBNodeRef = @"nodeRef";
static NSString *const kBShortName = @"shortName";
static NSString *const kBEnRetard = @"enRetard";
static NSString *const kBImage = @"image";
static NSString *const kBShowAVenir = @"showAVenir";
static NSString *const kBHabilitation = @"habilitation";
static NSString *const kBAArchiver = @"aArchiver";
static NSString *const kBATraiter = @"aTraiter";
static NSString *const kBIdentifier = @"identifier";
static NSString *const kBIsSecretaire = @"isSecretaire";
static NSString *const kBName = @"name";
static NSString *const kBRetournes = @"retournes";
static NSString *const kBDossiersDelegues = @"dossiersDelegues";


@interface ADLResponseBureau : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *level;
@property (nonatomic) bool hasSecretaire;
@property (nonatomic, strong) NSString *collectivite;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSNumber *enPreparation;
@property (nonatomic, strong) NSString *nodeRef;
@property (nonatomic, strong) NSString *shortName;
@property (nonatomic, strong) NSNumber *enRetard;
@property (nonatomic, strong) NSString *image;
@property (nonatomic) bool showAVenir;
@property (nonatomic, strong) NSDictionary *habilitation;
@property (nonatomic, strong) NSNumber *aArchiver;
@property (nonatomic, strong) NSNumber *aTraiter;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) bool isSecretaire;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *retournes;
@property (nonatomic, strong) NSNumber *dossiersDelegues;


@end
