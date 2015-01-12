
#import <Foundation/Foundation.h>

@interface ADLResponseDossier : NSObject

@property (nonatomic) int total;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *actionDemandee;
@property (nonatomic) bool isSent;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *bureauName;
@property (nonatomic, strong) NSString *creator;
@property (nonatomic, strong) NSString *identifier; // id
@property (nonatomic, strong) NSString *title;
@property (nonatomic) int pendingFile;
@property (nonatomic, strong) NSString *banetteName;
@property (nonatomic) int skipped;
@property (nonatomic, strong) NSString *sousType;
@property (nonatomic) bool isSignPapier;
@property (nonatomic) bool isXemEnabled;
@property (nonatomic) bool hasRead;
@property (nonatomic) bool readingMandatory;
@property (nonatomic, strong) NSDictionary *documentPrincipal;
@property (nonatomic) bool locked;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic) bool isRead;
@property (nonatomic) long dateEmission;
@property (nonatomic) bool includeAnnexes;

@end
