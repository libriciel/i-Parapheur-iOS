//
//  ADLResponseDossier.h
//  iParapheur
//
//  Created by Adrien Bricchi on 12/01/2015.
//
//

#import <Foundation/Foundation.h>

@interface ADLResponseDossier : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *nomTdT;
@property (nonatomic) bool includeAnnexes;
@property (nonatomic) bool locked;
@property (nonatomic) bool readingMandatory;
@property (nonatomic, strong) NSNumber *dateEmission;
@property (nonatomic, strong) NSString *visibility;
@property (nonatomic) bool isRead;
@property (nonatomic, strong) NSString *actionDemandee;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSArray *documents;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) bool isSignPapier;
@property (nonatomic, strong) NSNumber *dateLimite;
@property (nonatomic) bool hasRead;
@property (nonatomic) bool isXemEnabled;
@property (nonatomic, strong) NSArray *actions;
@property (nonatomic, strong) NSString *banetteName;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) bool canAdd;
@property (nonatomic, strong) NSString *protocole;
@property (nonatomic, strong) NSDictionary *metadatas;
@property (nonatomic, strong) NSString *xPathSignature;
@property (nonatomic, strong) NSString *sousType;
@property (nonatomic, strong) NSString *bureauName;
@property (nonatomic) bool isSent;

@end
