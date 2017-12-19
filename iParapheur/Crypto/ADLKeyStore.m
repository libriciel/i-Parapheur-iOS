/*
 * Copyright 2012-2017, Libriciel SCOP.
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
#import "PrivateKey.h"


@implementation ADLKeyStore

@synthesize managedObjectContext;


static NSString *ISO_8601_FORMAT = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";


static int PKCS7_type_is_other(PKCS7 *p7) {

	int isOther = 1;

	int nid = OBJ_obj2nid(p7->type);

	switch (nid) {
		case NID_pkcs7_data:
		case NID_pkcs7_signed:
		case NID_pkcs7_enveloped:
		case NID_pkcs7_signedAndEnveloped:
		case NID_pkcs7_digest:
		case NID_pkcs7_encrypted:
			isOther = 0;
			break;
		default:
			isOther = 1;
	}

	return isOther;

}


static ASN1_OCTET_STRING *PKCS7_get_octet_string(PKCS7 *p7) {

	if (PKCS7_type_is_data(p7))
		return p7->d.data;
	if (PKCS7_type_is_other(p7) && p7->d.other
			&& (p7->d.other->type == V_ASN1_OCTET_STRING))
		return p7->d.other->value.octet_string;
	return NULL;
}


static int adl_do_pkcs7_signed_attrib(PKCS7_SIGNER_INFO *si, unsigned char *md_data, unsigned int md_len) {


	/* Add signing time if not already present */
	if (!PKCS7_get_signed_attribute(si, NID_pkcs9_signingTime)) {
		if (!PKCS7_add0_attrib_signing_time(si, NULL)) {
			PKCS7err(PKCS7_F_DO_PKCS7_SIGNED_ATTRIB,
					ERR_R_MALLOC_FAILURE);
			return 0;
		}
	}

	if (!PKCS7_add1_attrib_digest(si, md_data, md_len)) {
		PKCS7err(PKCS7_F_DO_PKCS7_SIGNED_ATTRIB, ERR_R_MALLOC_FAILURE);
		return 0;
	}

	/* Now sign the attributes */
	if (!PKCS7_SIGNER_INFO_sign(si))
		return 0;

	return 1;
}


int ADL_PKCS7_dataFinal(PKCS7 *p7, BIO *bio, unsigned char md_data[], unsigned int md_len) {

	int ret = 0;
	int i;
	BIO *btmp;
	PKCS7_SIGNER_INFO *si;
	STACK_OF(X509_ATTRIBUTE) *sk;
	STACK_OF(PKCS7_SIGNER_INFO) *si_sk = NULL;
	ASN1_OCTET_STRING *os = NULL;

	i = OBJ_obj2nid(p7->type);
	p7->state = PKCS7_S_HEADER;

	switch (i) {
		case NID_pkcs7_data:
			os = p7->d.data;
			break;
		case NID_pkcs7_signedAndEnveloped:
			/* XXXXXXXXXXXXXXXX */
			si_sk = p7->d.signed_and_enveloped->signer_info;
			os = p7->d.signed_and_enveloped->enc_data->enc_data;
			if (!os) {
				os = M_ASN1_OCTET_STRING_new();
				if (!os) {
					PKCS7err(PKCS7_F_PKCS7_DATAFINAL, ERR_R_MALLOC_FAILURE);
					goto err;
				}
				p7->d.signed_and_enveloped->enc_data->enc_data = os;
			}
			break;
		case NID_pkcs7_enveloped:
			/* XXXXXXXXXXXXXXXX */
			os = p7->d.enveloped->enc_data->enc_data;
			if (!os) {
				os = M_ASN1_OCTET_STRING_new();
				if (!os) {
					PKCS7err(PKCS7_F_PKCS7_DATAFINAL, ERR_R_MALLOC_FAILURE);
					goto err;
				}
				p7->d.enveloped->enc_data->enc_data = os;
			}
			break;
		case NID_pkcs7_signed:
			si_sk = p7->d.sign->signer_info;
			os = PKCS7_get_octet_string(p7->d.sign->contents);
			/* If detached data then the content is excluded */
			if (PKCS7_type_is_data(p7->d.sign->contents) && p7->detached) {
				M_ASN1_OCTET_STRING_free(os);
				p7->d.sign->contents->d.data = NULL;
			}
			break;

		case NID_pkcs7_digest:
			os = PKCS7_get_octet_string(p7->d.digest->contents);
			/* If detached data then the content is excluded */
			if (PKCS7_type_is_data(p7->d.digest->contents) && p7->detached) {
				M_ASN1_OCTET_STRING_free(os);
				p7->d.digest->contents->d.data = NULL;
			}
			break;

		default:
			PKCS7err(PKCS7_F_PKCS7_DATAFINAL, PKCS7_R_UNSUPPORTED_CONTENT_TYPE);
			goto err;
	}

	if (si_sk != NULL) {
		for (i = 0; i < sk_PKCS7_SIGNER_INFO_num(si_sk); i++) {
			si = sk_PKCS7_SIGNER_INFO_value(si_sk, i);
			if (si->pkey == NULL)
				continue;

			// j = OBJ_obj2nid(si->digest_alg->algorithm);
			// btmp=bio;

			sk = si->auth_attr;

			/* If there are attributes, we add the digest
			 * attribute and only sign the attributes */
			if (sk_X509_ATTRIBUTE_num(sk) > 0) {
				if (!adl_do_pkcs7_signed_attrib(si, md_data, md_len))
					goto err;
			}
		}
	}

	if (!PKCS7_is_detached(p7) && !(os->flags & ASN1_STRING_FLAG_NDEF)) {
		char *cont;
		long contlen;
		btmp = BIO_find_type(bio, BIO_TYPE_MEM);
		if (btmp == NULL) {
			PKCS7err(PKCS7_F_PKCS7_DATAFINAL, PKCS7_R_UNABLE_TO_FIND_MEM_BIO);
			goto err;
		}
		contlen = BIO_get_mem_data(btmp, &cont);
		/* Mark the BIO read only then we can use its copy of the data
		 * instead of making an extra copy.
		 */
		BIO_set_flags(btmp, BIO_FLAGS_MEM_RDONLY);
		BIO_set_mem_eof_return(btmp, 0);
		ASN1_STRING_set0(os, (unsigned char *) cont, contlen);
	}
	ret = 1;
	err:
	return (ret);
}


- (void)checkUpdates {

	// Previously, full p12 file path was keeped in the DB.
	// But the app data folder path changes on every update.
	// Here we have to check previous data stored, and patch it.

	NSArray *keys = [self listPrivateKeys];

	for (PrivateKey *oldKey in keys) {
		if (oldKey.p12Filename.pathComponents.count != 2) {

			NSString *relativePath = [NSString stringWithFormat:@"%@/%@",
			                                                    [NSBundle mainBundle].bundleIdentifier,
			                                                    oldKey.p12Filename.lastPathComponent];
			oldKey.p12Filename = relativePath;

			[self.managedObjectContext save:nil];
		}
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


- (void)recursiveCopyURL:(NSURL *)from
                   toUrl:(NSURL *)to {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *fileList = [fileManager contentsOfDirectoryAtPath:[from path]
	                                                     error:nil];
	for (NSString *s in fileList) {
		NSURL *newFileURL = [to URLByAppendingPathComponent:s];
		NSURL *oldFileURL = [from URLByAppendingPathComponent:s];
		if (![fileManager fileExistsAtPath:[newFileURL path]]) {
			//File does not exist, copy it
			[fileManager copyItemAtPath:[oldFileURL path]
			                     toPath:[newFileURL path]
			                      error:nil];
		} else {
			// NSLog(@"File exists: %@", [newFileURL path]);
		}
	}
}


- (NSString *)UUID {

	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
	CFRelease(uuidObj);
	return uuidString;
}


#pragma mark - Public API


- (void)resetKeyStore {

	NSArray *pkeys = [self listPrivateKeys];
	for (PrivateKey *key in pkeys) {
		NSError *error = nil;
		if (![[NSFileManager defaultManager] removeItemAtPath:key.p12Filename
		                                                error:&error])
			NSLog(@"Unable to delete file: %@", error.localizedDescription);
		[self.managedObjectContext deleteObject:key];
	}
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Something's gone seriously wrong
		NSLog(@"Error clearing KeyStore: %@", error.localizedDescription);

	}
}


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


- (NSData *)PKCS7Sign:(NSString *)p12Path
         withPassword:(NSString *)password
              andData:(NSData *)data
                error:(NSError **)error {

	/* Read PKCS12 */
	FILE *fp;
	EVP_PKEY *pkey;
	X509 *cert;
	STACK_OF(X509) *ca = NULL;
	PKCS12 *p12;
	// int i = 0;
	//unsigned char *alias = NULL;

	const char *p12_file_path = [p12Path cStringUsingEncoding:NSUTF8StringEncoding];
	const char *p12_password = [password cStringUsingEncoding:NSUTF8StringEncoding];

	OpenSSL_add_all_algorithms();
	ERR_load_crypto_strings();
	EVP_add_digest(EVP_sha1());
	NSData *retVal = nil;

	if (!(fp = fopen(p12_file_path, "rb"))) {
		NSString *localizedDescritpion = [NSString stringWithFormat:@"Le fichier %@ n'a pas pu être ouvert",
		                                                            p12Path.lastPathComponent];
		perror("Opening p12 file error : ");

		[self emitFileIOError:error
		 localizedDescritpion:localizedDescritpion];
	} else {
		p12 = d2i_PKCS12_fp(fp, NULL);
		fclose(fp);
		if (!p12) {
			NSString *localizedDescritpion = [NSString stringWithFormat:@"Impossible de lire %@",
			                                                            p12Path.lastPathComponent];
			[self emitFileIOError:error
			 localizedDescritpion:localizedDescritpion];
		} else {
			if (!PKCS12_parse(p12, p12_password, &pkey, &cert, &ca)) {
				NSString *localizedDescription = [NSString stringWithFormat:@"Impossible de d'ouvrir %@ verifiez le mot de passe",
				                                                            p12Path.lastPathComponent];
				[self emitError:error
		   localizedDescription:localizedDescription
		                 domain:P12ErrorDomain
		                   code:P12OpenErrorCode];
			} else {
				retVal = [self signData:data
				                   pkey:pkey
				                   cert:cert];
			}
		}
		PKCS12_free(p12);
	}

	return retVal;
}


- (void)emitFileIOError:(NSError **)error
   localizedDescritpion:(NSString *)localizedDescritpion {

	[self  emitError:error
localizedDescription:localizedDescritpion
              domain:NSPOSIXErrorDomain
                code:ENOENT];
}


- (void)   emitError:(NSError **)error
localizedDescription:(NSString *)localizedDescription
              domain:(NSString *)domain
                code:(int)code {

#ifdef DEBUG_KEYSTORE
	ERR_print_errors_fp(stderr);
#endif
	if (error) {
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: localizedDescription};
		*error = [NSError errorWithDomain:domain
		                             code:code
		                         userInfo:userInfo];
	}
}


- (NSData *)signData:(NSData *)data
                pkey:(EVP_PKEY *)pkey
                cert:(X509 *)cert {

	BIO *bio_data = BIO_new(BIO_s_mem());
	BIO_write(bio_data, data.bytes, data.length);

	PKCS7 *p7 = PKCS7_new();
	PKCS7_set_type(p7, NID_pkcs7_signed);
	PKCS7_SIGNER_INFO *si = PKCS7_add_signature(p7, cert, pkey, EVP_sha1());

	if (si == NULL)
		return nil;

	/* If you do this then you get signing time automatically added */
	PKCS7_add_signed_attribute(si, NID_pkcs9_contentType, V_ASN1_OBJECT, OBJ_nid2obj(NID_pkcs7_data));

	/* we may want to add more */
	PKCS7_add_certificate(p7, cert);

	/* Set the content of the signed to 'data' */
	PKCS7_content_new(p7, NID_pkcs7_data);

	PKCS7_set_detached(p7, 1);
	BIO *p7bio;

	if ((p7bio = PKCS7_dataInit(p7, NULL)) == NULL)
		return nil;

	int i = 0;
	char buf[255];
	for (;;) {
		i = BIO_read(bio_data, buf, sizeof(buf));

		if (i <= 0)
			break;

		BIO_write(p7bio, buf, i);
	}

	if (!ADL_PKCS7_dataFinal(p7, p7bio, (unsigned char *) data.bytes, data.length))
		return nil;

	BIO_free(p7bio);
	BIO *signature_bio = BIO_new(BIO_s_mem());
	PEM_write_bio_PKCS7(signature_bio, p7);
	(void) BIO_flush(signature_bio);

	char *outputBuffer;
	long outputLength = BIO_get_mem_data(signature_bio, &outputBuffer);

	NSData *retVal = [NSData dataWithBytes:outputBuffer
	                                length:(NSUInteger) outputLength];

#ifdef DEBUG
	PEM_write_PKCS7(stdout, p7);
#endif

	PKCS7_free(p7);
	BIO_free_all(signature_bio);

	return retVal;
}

//
//- (NSData *)signRsaData:(NSData *)data
//                   pkey:(EVP_PKEY *)pkey
//                   cert:(X509 *)cert {
//
//    // these are structs and arrays used by the evp message digest functions
//	EVP_MD_CTX mdctx;
//	const EVP_MD *md;
//	char mess1[] = "fu\n";
//	char mess2[] = "bar\n";
//	char seedStr[7];
//	unsigned char md_value[EVP_MAX_MD_SIZE];
//	int md_len, seed, i;
//
//    // this NSString I'm going to use for comparing later on
//	NSMutableString *curKey = [NSMutableString stringWithCapacity:40];
//
//	OpenSSL_add_all_digests();
//
//    // create a SHA digest
//	md = EVP_get_digestbyname("sha1");
//	EVP_DigestInit(&mdctx, md);
//	EVP_DigestUpdate(&mdctx, mess1, strlen(mess1));
//	EVP_DigestUpdate(&mdctx, mess2, strlen(mess2));
//	EVP_DigestUpdate(&mdctx, seedStr, strlen(seedStr));
//	EVP_DigestFinal(&mdctx, md_value, &md_len);
//
//    // inspect md_value[] and do stuff with it
//	for(i = 0; i < md_len; i++)
//		[curKey appendFormat:@"%02x",  md_value[i]];
//}


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

	NSPredicate *predicate = [NSPredicate predicateWithFormat:
			                                      @"commonName=%@ AND caName=%@ AND serialNumber=%@",
			                                      x509Values[@"commonName"],
			                                      x509Values[@"issuerName"],
			                                      x509Values[@"serialNumber"]];

	request.predicate = predicate;

	if (error)
		*error = nil;

	NSArray *array = [self.managedObjectContext executeFetchRequest:request
	                                                          error:error];

	if (array.count == 0) {

		NSString *newPath = [self.applicationDataDirectory.path stringByAppendingPathComponent:self.UUID];

		// move the file to applicationDataDirectory
		[NSFileManager.defaultManager moveItemAtPath:p12Path
		                                      toPath:newPath
		                                       error:error];

		// generate an entry for the new Key

		PrivateKey *newPrivateKey = [NSEntityDescription insertNewObjectForEntityForName:@"PrivateKey"
		                                                          inManagedObjectContext:self.managedObjectContext];

		NSDateFormatter *formatter = NSDateFormatter.new;
		formatter.dateFormat = ISO_8601_FORMAT;

		newPrivateKey.p12Filename = newPath;
		newPrivateKey.publicKey = [x509Values[@"publicKey"] dataUsingEncoding:NSUTF8StringEncoding];
		newPrivateKey.serialNumber = x509Values[@"serialNumber"];
		newPrivateKey.notBefore = [formatter dateFromString:x509Values[@"notBefore"]];
		newPrivateKey.notAfter = [formatter dateFromString:x509Values[@"notAfter"]];
		newPrivateKey.commonName = x509Values[@"commonName"];
		newPrivateKey.caName = x509Values[@"issuerName"];

		error = nil;
		if (![self.managedObjectContext save:error]) {
			// Something's gone seriously wrong
			NSLog(@"Error saving new PrivateKey: %@", (*error).localizedDescription);
		}
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


+ (NSDictionary *)parseX509Values:(X509 *)certX509 {

	// Fetch values from p12, with OpenSSL

	int len = 0;
	unsigned char *aliasChar = X509_alias_get0(certX509, &len);

	char issuerChar[256];
	X509_NAME *issuerX509Name = X509_get_issuer_name(certX509);
	X509_NAME_oneline(issuerX509Name, issuerChar, 256);

	ASN1_TIME *notBeforeAsn1Time = X509_get_notBefore(certX509);
	ASN1_TIME *notAfterAsn1Time = X509_get_notAfter(certX509);;

	ASN1_INTEGER *serialAsn1 = X509_get_serialNumber(certX509);
	BIGNUM *serialBigNumber = ASN1_INTEGER_to_BN(serialAsn1, NULL);
	char *serialChar = BN_bn2hex(serialBigNumber);

	NSData *certNsData = X509_to_NSData(certX509);

	// Convert values into Foundation classes

	NSString *aliasString = [NSString stringWithCString:(const char *) aliasChar encoding:NSUTF8StringEncoding];
	NSString *issuerString = [NSString stringWithCString:(const char *) issuerChar encoding:NSUTF8StringEncoding];
	NSString *serialString = [NSString stringWithCString:(const char *) serialChar encoding:NSUTF8StringEncoding];
	NSString *certString = [NSString.alloc initWithData:certNsData
	                                           encoding:NSUTF8StringEncoding];

	NSDate *notBeforeDate = [ADLKeyStore asn1TimeToNsDate:notBeforeAsn1Time];
	NSDate *notAfterDate = [ADLKeyStore asn1TimeToNsDate:notAfterAsn1Time];

	NSDateFormatter *formatter = NSDateFormatter.new;
	formatter.dateFormat = ISO_8601_FORMAT;

	NSString *notBeforeString = [formatter stringFromDate:notBeforeDate];
	NSString *notAfterString = [formatter stringFromDate:notAfterDate];

	// Result

	return @{
			@"commonName": aliasString,
			@"issuerName": issuerString,
			@"notBefore": notBeforeString,
			@"notAfter": notAfterString,
			@"serialNumber": serialString,
			@"publicKey": certString
	};
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


@end
