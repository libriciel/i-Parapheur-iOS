
#import <Foundation/Foundation.h>
#import "Mantle/Mantle.h"

@interface ADLResponseDossiers : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *total;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *actionDemandee;
@property (nonatomic) bool isSent;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *bureauName;
@property (nonatomic, strong) NSString *creator;
@property (nonatomic, strong) NSString *identifier; // id
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *pendingFile;
@property (nonatomic, strong) NSString *banetteName;
@property (nonatomic, strong) NSNumber *skipped;
@property (nonatomic, strong) NSString *sousType;
@property (nonatomic) bool isSignPapier;
@property (nonatomic) bool isXemEnabled;
@property (nonatomic) bool hasRead;
@property (nonatomic) bool readingMandatory;
@property (nonatomic, strong) NSDictionary *documentPrincipal;
@property (nonatomic) bool locked;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic) bool isRead;
@property (nonatomic, strong) NSNumber *dateEmission;
@property (nonatomic, strong) NSNumber *dateLimite;
@property (nonatomic) bool includeAnnexes;

@end
