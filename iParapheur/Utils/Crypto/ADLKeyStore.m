/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
#import "ADLKeyStore.h"
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#import <OpenSSL-Universal/openssl/x509v3.h>
#import "iParapheur-Swift.h"
#import "NSData+Base64.h"


@implementation ADLKeyStore

@synthesize managedObjectContext;


- (void)checkUpdates {

    // Previously, full p12 file path was keeped in the DB.
    // But the app data folder path changes on every update.
    // Here we have to check previous data stored, and patch it.

    NSArray *keys = [self listPrivateKeys];

    for (Certificate *oldKey in keys) {
//        if (oldKey.p12Filename.pathComponents.count != 2) { TODO Adrien payload
//
//            NSString *relativePath = [NSString stringWithFormat:@"%@/%@",
//                                                                [NSBundle mainBundle].bundleIdentifier,
//                                                                oldKey.p12Filename.lastPathComponent];
//            oldKey.p12Filename = relativePath;
//
//            [self.managedObjectContext save:nil];
//        }
    }
}


NSData *X509_to_NSData(X509 *cert) {

    unsigned char *cert_data = NULL;
    BIO *mem = BIO_new(BIO_s_mem());
    PEM_write_bio_X509(mem, cert);
    (void) BIO_flush(mem);
    int base64Length = BIO_get_mem_data(mem, &cert_data);
    NSData *retVal = [NSData dataWithBytes:cert_data
                                    length:(NSUInteger) base64Length];
    return retVal;
}


- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
                           inDomain:(NSSearchPathDomainMask)domainMask
                appendPathComponent:(NSString *)appendComponent
                              error:(NSError **)errorOut {

    // Search for the path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory,
            domainMask,
            YES);
    if ([paths count] == 0) {
        // *** creation and return of error object omitted for space
        return nil;
    }

    // Normally only need the first path
    NSString *resolvedPath = paths[0];

    if (appendComponent) {
        resolvedPath = [resolvedPath
                stringByAppendingPathComponent:appendComponent];
    }

    // Create the path if it doesn't exist
    NSError *error;
    BOOL success = [[NSFileManager defaultManager]
            createDirectoryAtPath:resolvedPath
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (!success) {
        if (errorOut) {
            *errorOut = error;
        }
        return nil;
    }

    // If we've made it this far, we have a success
    if (errorOut) {
        *errorOut = nil;
    }
    return resolvedPath;
}


- (NSURL *)applicationDataDirectory {

    NSString *appBundleId = [[NSBundle mainBundle] bundleIdentifier];

    NSError *error;
    NSString *result =
            [self
                    findOrCreateDirectory:NSApplicationSupportDirectory
                                 inDomain:NSUserDomainMask
                      appendPathComponent:appBundleId
                                    error:&error];
    if (error) {
        NSLog(@"Unable to find or create application support directory:\n%@", error);
    }
    return [NSURL fileURLWithPath:result];
}


#pragma mark - Public API


- (NSArray *)listPrivateKeys {

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PrivateKey"
                                              inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = NSFetchRequest.new;
    request.entity = entity;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor.alloc initWithKey:@"commonName"
                                                                 ascending:YES];
    request.sortDescriptors = @[sortDescriptor];

    // Fetch the records and handle an error
    NSError *error;
    NSArray *pkeys = [self.managedObjectContext executeFetchRequest:request
                                                              error:&error];

    return pkeys;
}


- (BOOL)addKey:(NSString *)p12Path
  withPassword:(NSString *)password
         error:(NSError **)error {

    // Parse X509 values

    NSDictionary *x509Values = [ADLKeyStore getX509ValuesforP12:p12Path
                                                   withPassword:password];

    if (!x509Values)    // TODO : error message
        return NO;

    // prepare data for the PrivateKey Entity

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PrivateKey"
                                                         inManagedObjectContext:self.managedObjectContext];

    NSFetchRequest *request = NSFetchRequest.new;
    request.entity = entityDescription;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"commonName=%@ AND caName=%@ AND serialNumber=%@",
                                                              x509Values[@"commonName"],
                                                              x509Values[@"issuerName"],
                                                              x509Values[@"serialNumber"]];

    request.predicate = predicate;

    if (error)
        *error = nil;

    NSArray *array = [self.managedObjectContext executeFetchRequest:request
                                                              error:error];

    if (array.count == 0) {

        NSString *newPath = [self.applicationDataDirectory.path stringByAppendingPathComponent:NSUUID.UUID.UUIDString];

        // move the file to applicationDataDirectory
        [NSFileManager.defaultManager moveItemAtPath:p12Path
                                              toPath:newPath
                                               error:error];

        // generate an entry for the new Key

        Certificate *newPrivateKey = [NSEntityDescription insertNewObjectForEntityForName:Certificate.ENTITY_NAME
                                                                   inManagedObjectContext:ModelsDataController.context];

        NSString *p12FileName = [NSString stringWithFormat:@"coop.adullact-projet.iparapheur/%@", newPath.lastPathComponent];
        NSDictionary *payload = @{Certificate.PAYLOAD_P12_FILENAME: p12FileName};
        NSError *jsonError = nil;
        NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&jsonError];

        NSString *publicKeyB64 = [CryptoUtils cleanupPublicKeyWithPublicKey:x509Values[@"publicKey"]];
        NSData *publicKeyData = [NSData dataFromBase64String:publicKeyB64];

        newPrivateKey.payload = payloadData;
        newPrivateKey.publicKey = publicKeyData;
        newPrivateKey.serialNumber = x509Values[@"serialNumber"];
        newPrivateKey.notBefore = (NSDate *) x509Values[@"notBefore"];
        newPrivateKey.notAfter = (NSDate *) x509Values[@"notAfter"];
        newPrivateKey.commonName = x509Values[@"commonName"];
        newPrivateKey.caName = x509Values[@"issuerName"];

        [ModelsDataController save];

    } else {

        NSLog(@"Object already in KeyStore %@", [array[0] commonName]);
        *error = [NSError errorWithDomain:P12ErrorDomain
                                     code:P12AlreadyImported
                                 userInfo:@{NSLocalizedDescriptionKey: @"Ce certificat a déjà été importé"}];
        return NO;
    }

    return YES;
}


#pragma mark - Utils


// <editor-fold desc="X509 PEM utils">


+ (X509 *)x509FromPem:(NSString *)publicKeyPem {

    NSString *cleanedPublicKey = [CryptoUtils wrappedPemWithPublicKey:publicKeyPem];

    X509 *cert = NULL;
    BIO *bio = NULL;

    bio = BIO_new_mem_buf(cleanedPublicKey.UTF8String, cleanedPublicKey.length);
    cert = PEM_read_bio_X509(bio, &cert, NULL, NULL);

    BIO_free(bio);
    return cert;
}


+ (NSDictionary *)parseX509Values:(X509 *)certX509 {

    // Fetch values from p12, with OpenSSL

    int len = 0;
    unsigned char *aliasChar = X509_alias_get0(certX509, &len);

    // Issuer in RFC2253

    BIO *issuerBio = BIO_new(BIO_s_mem());
    X509_NAME *issuerX509Name = X509_get_issuer_name(certX509);
    X509_NAME_print_ex(issuerBio, issuerX509Name, 0, XN_FLAG_RFC2253);
    NSString *issuerString = [self bioToString:issuerBio];
    BIO_free_all(issuerBio);

    BIO *subjectBio = BIO_new(BIO_s_mem());
    X509_NAME *subjectX509Name = X509_get_subject_name(certX509);
    X509_NAME_print_ex(subjectBio, subjectX509Name, 0, XN_FLAG_RFC2253);
    NSString *subjectString = [self bioToString:subjectBio];
    BIO_free_all(subjectBio);

    // Other fields

    ASN1_TIME *notBeforeAsn1Time = X509_get_notBefore(certX509);
    ASN1_TIME *notAfterAsn1Time = X509_get_notAfter(certX509);

    ASN1_INTEGER *serialAsn1 = X509_get_serialNumber(certX509);
    BIGNUM *serialBigNumber = ASN1_INTEGER_to_BN(serialAsn1, NULL);
    char *serialChar = BN_bn2dec(serialBigNumber);

    NSData *certNsData = X509_to_NSData(certX509);

    // Convert values into Foundation classes

    NSString *aliasString = @"";
    if (aliasChar) {
        aliasString = [NSString stringWithCString:(const char *) aliasChar encoding:NSUTF8StringEncoding];
    }

    NSString *serialString = @"";
    if (serialChar) {
        serialString = [NSString stringWithCString:(const char *) serialChar encoding:NSUTF8StringEncoding];
    }

    NSString *keyUsageString = @"";
    NSDictionary *x509Extensions = [self parseX509V3Extensions:certX509];
    if ([x509Extensions.allKeys containsObject:@"X509v3 Key Usage"])
        keyUsageString = x509Extensions[@"X509v3 Key Usage"];

    NSString *certString = [NSString.alloc initWithData:certNsData encoding:NSUTF8StringEncoding];

    NSDate *notBeforeDate = [ADLKeyStore asn1TimeToNsDate:notBeforeAsn1Time];
    NSDate *notAfterDate = [ADLKeyStore asn1TimeToNsDate:notAfterAsn1Time];

    // Result

    NSDictionary *result = @{
            @"subject": subjectString,
            @"commonName": aliasString,
            @"issuerName": issuerString,
            @"notBefore": notBeforeDate,
            @"notAfter": notAfterDate,
            @"serialNumber": serialString,
            @"publicKey": certString,
            @"keyUsage": keyUsageString
    };

    result = [StringsUtils cleanupX509CertificateValues:result];
    return result;
}


+ (NSDictionary *)parseX509V3Extensions:(X509 *)x509Cert {

    NSMutableDictionary *result = NSMutableDictionary.new;
    STACK_OF(X509_EXTENSION) *ext_list = x509Cert->cert_info->extensions;

    if (sk_X509_EXTENSION_num(ext_list) <= 0)
        return result;

    for (int i = 0; i < sk_X509_EXTENSION_num(ext_list); i++) {

        X509_EXTENSION *ext = sk_X509_EXTENSION_value(ext_list, i);

        // Key parsing

        BIO *bioKey = BIO_new(BIO_s_mem());
        ASN1_OBJECT *obj = X509_EXTENSION_get_object(ext);
        i2a_ASN1_OBJECT(bioKey, obj);
        NSString *key = [self bioToString:bioKey];
        BIO_free_all(bioKey);

        // Object parsing

        BIO *bioValue = BIO_new(BIO_s_mem());
        X509V3_EXT_print(bioValue, ext, NULL, NULL);
        NSString *value = [self bioToString:bioValue];
        BIO_free_all(bioValue);

        // Building result

        result[key] = value;
    }

    return result;
}


+ (NSString *)bioToString:(BIO *)bio {

    int len = BIO_pending(bio);

    if (len == 0) {
        return @"";
    }

    char *out = calloc((size_t) (len + 1), 1);
    int i = BIO_read(bio, out, len);

    NSData *data = [NSData dataWithBytes:out length:(NSUInteger) i];
    NSString *value = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
    return value;
}


+ (NSDate *)asn1TimeToNsDate:(ASN1_TIME *)time {

    NSDate *resultDate = nil;

    ASN1_GENERALIZEDTIME *generalizedTime = ASN1_TIME_to_generalizedtime(time, NULL);
    if (generalizedTime != NULL) {
        unsigned char *generalizedTimeData = ASN1_STRING_data(generalizedTime);

        // ASN1 generalized times look like this: "20131114230046Z"
        //                                format:  YYYYMMDDHHMMSS
        //                               indices:  01234567890123
        //                                                   1111
        // There are other formats (e.g. specifying partial seconds or
        // time zones) but this is good enough for our purposes since
        // we only use the date and not the time.
        //
        // (Source: http://www.obj-sys.com/asn1tutorial/node14.html)

        NSString *timeStr = [NSString stringWithUTF8String:(char *) generalizedTimeData];
        NSDateComponents *dateComponents = NSDateComponents.new;

        dateComponents.year = [timeStr substringWithRange:NSMakeRange(0, 4)].intValue;
        dateComponents.month = [timeStr substringWithRange:NSMakeRange(4, 2)].intValue;
        dateComponents.day = [timeStr substringWithRange:NSMakeRange(6, 2)].intValue;
        dateComponents.hour = [timeStr substringWithRange:NSMakeRange(8, 2)].intValue;
        dateComponents.minute = [timeStr substringWithRange:NSMakeRange(10, 2)].intValue;
        dateComponents.second = [timeStr substringWithRange:NSMakeRange(12, 2)].intValue;

        NSCalendar *calendar = NSCalendar.currentCalendar;
        resultDate = [calendar dateFromComponents:dateComponents];
    }

    return resultDate;
}


// </editor-fold desc="X509 PEM utils">


+ (NSDictionary *)getX509ValuesforP12:(NSString *)path
                         withPassword:(NSString *)password {

    NSString *p12Path = path;

    FILE *fp;
    EVP_PKEY *pkey;
    X509 *certX509;
    STACK_OF(X509) *ca = NULL;
    PKCS12 *p12;

    const char *p12_file_path = [p12Path cStringUsingEncoding:NSUTF8StringEncoding];
    const char *p12_password = [password cStringUsingEncoding:NSUTF8StringEncoding];

    OpenSSL_add_all_algorithms();
    ERR_load_crypto_strings();
    EVP_add_digest(EVP_sha1());

    // Check p12 file

    if (!(fp = fopen(p12_file_path, "rb"))) {
        NSLog(@"Update certificate error - Can't open file %@", p12Path.lastPathComponent);
        return nil;
    }

    p12 = d2i_PKCS12_fp(fp, NULL);
    fclose(fp);

    if (!p12) {
        PKCS12_free(p12);
        NSLog(@"Update certificate error - Can't read file %@", p12Path.lastPathComponent);
        return nil;
    }

    if (!PKCS12_parse(p12, p12_password, &pkey, &certX509, &ca)) {
        NSLog(@"Update certificate error - Wrong password %@ / %@", p12Path.lastPathComponent, password);
        PKCS12_free(p12);
        return nil;
    }

    PKCS12_free(p12);

    if (!certX509) {
        NSLog(@"Update certificate error - no certificate in KeyStore %@", p12Path.lastPathComponent);
        return nil;
    }

    return [self parseX509Values:certX509];
}


@end
