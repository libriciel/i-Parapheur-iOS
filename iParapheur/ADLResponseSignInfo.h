//
//  ADLResponseSignInfo.h
//  iParapheur
//
//  Created by Adrien Bricchi on 19/01/2015.
//
//

#import <Foundation/Foundation.h>

@interface ADLResponseSignInfo : NSObject

@property (nonatomic, strong) NSString *pesid;
@property (nonatomic, strong) NSString *peshash;
@property (nonatomic, strong) NSString *pespolicydesc;
@property (nonatomic, strong) NSString *pescountryname;
@property (nonatomic, strong) NSString *pespostalcode;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, strong) NSString *pesspuri;
@property (nonatomic, strong) NSString *pesencoding;
@property (nonatomic, strong) NSString *pesclaimedrole;
@property (nonatomic, strong) NSString *pespolicyid;
@property (nonatomic, strong) NSString *pespolicyhash;
@property (nonatomic, strong) NSString *p7s;
@property (nonatomic, strong) NSString *pescity;

@end
