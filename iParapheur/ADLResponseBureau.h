
#import <Foundation/Foundation.h>

@interface ADLResponseBureau : NSObject

@property (nonatomic, strong) NSNumber *level;
@property (nonatomic) bool hasSecretaire;
@property (nonatomic, strong) NSString *collectivite;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSNumber *enPreparation; //en-preparation
@property (nonatomic, strong) NSString *nodeRef;
@property (nonatomic, strong) NSString *shortName;
@property (nonatomic, strong) NSNumber *enRetard; //en-retard
@property (nonatomic, strong) NSString *image;
@property (nonatomic) bool showAVenir; //show_a_venir
@property (nonatomic, strong) NSDictionary *habilitation;
@property (nonatomic, strong) NSNumber *aArchiver; //a-archiver
@property (nonatomic, strong) NSNumber *aTraiter; //a-traiter
@property (nonatomic, strong) NSString *id;
@property (nonatomic) bool isSecretaire;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *retournes;
@property (nonatomic, strong) NSNumber *dossierDelegues; //dossiers-delegues": 16

@end
