/*
 * Copyright 2012-2016, Adullact-Projet.
 * Contributors : SKROBS (2012)
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


- (void)checkUpdates;


- (void)resetKeyStore;


- (NSArray *)listPrivateKeys;


- (BOOL)addKey:(NSString *)p12Path
  withPassword:(NSString *)password
         error:(NSError **)error;


#pragma mark - Crypto methods


- (NSData *)PKCS7Sign:(NSString *)p12Path
         withPassword:(NSString *)password
              andData:(NSData *)data
                error:(NSError **)error;


#pragma mark - Utils


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


+ (NSDate *)asn1TimeToNSDate:(ASN1_TIME *)time;


@end

