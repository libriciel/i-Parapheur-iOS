/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 * Contributors : SKROBS (2012)
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
#import <CoreData/CoreData.h>
#include <openssl/cms.h>


enum {
    P12OpenErrorCode,
    P12AlreadyImported
};

#define P12ErrorDomain @"P12Errors"


@interface ADLKeyStore : NSObject {
    NSManagedObjectContext *managedObjectContext;
}

/* Only usable on the soft KeyStore*/

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;


#pragma mark - Key Management methods


- (NSArray *)listPrivateKeys;


- (BOOL)addKey:(NSString *)p12Path
  withPassword:(NSString *)password
         error:(NSError **)error;


// <editor-fold desc="X509 PEM utils">


+ (X509 *)x509FromPem:(NSString *)pem;


+ (NSDictionary *)parseX509Values:(X509 *)certX509;


+ (NSDictionary *)parseX509V3Extensions:(X509 *)x509Cert;


+ (NSDate *)asn1TimeToNsDate:(ASN1_TIME *)time;


// </editor-fold desc="X509 PEM utils">

/**
 * P12 data into Dictionary containing "commonName", "issuerName", "notBefore", "notAfter", "serialNumber", "publicKey",
 * or nil if something went wrong.
 *
 * The publicKey value is an NSData in UTF8 encoding.
 * notBefore and notAfter dates are in ISO 8601 encoding.
 *
 * @param path the p12 absolute path
 * @param password
 * @return a Dictionary of NSString
 */
+ (NSDictionary *)getX509ValuesforP12:(NSString *)p12Path
                         withPassword:(NSString *)password;


@end
