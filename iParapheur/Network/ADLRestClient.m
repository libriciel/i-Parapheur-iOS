/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
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
