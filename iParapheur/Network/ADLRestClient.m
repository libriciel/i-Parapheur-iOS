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
#import "ADLRestClient.h"


@implementation ADLRestClient


+ (id)sharedManager {

    static ADLRestClient *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (id)init {

    [self resetClient];
    return self;
}


- (void)resetClient {

    _restClientApi = nil;
    _restClientApi = [[ADLRestClientApi3 alloc] init];
}


- (NSError *)downloadCertificateUrlWithUrl:(NSString *)url
                                    onPath:(NSString *)localPath {

    NSError *error = nil;

    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (urlData) {

        NSString *filePath = [NSString stringWithFormat:@"%@/%@",
                                                        localPath,
                                                        url.lastPathComponent];
        [urlData writeToFile:filePath
                  atomically:YES];

        uint64_t fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                             error:&error].fileSize;
        NSLog(@"Downloaded - file : %@ (%llu)", filePath, fileSize);
    } else {
        error = [[NSError alloc] initWithDomain:url //AFURLRequestSerializationErrorDomain
                                           code:NSURLErrorBadURL
                                       userInfo:nil];
    }

    return error;
}


#pragma mark API calls


- (void)getTypology:(NSString *)bureauId
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

    [_restClientApi getTypology:bureauId
                        success:^(NSArray *typeList) {
                            success(typeList);
                        }
                        failure:^(NSError *error) {
                            failure(error);
                        }];
}


@end
