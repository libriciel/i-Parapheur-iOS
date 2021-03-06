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
#import "ADLRestClientApi3.h"
#import "iParapheur-Swift.h"


@implementation ADLRestClientApi3


- (id)init {

    // Fetch selected Account Id

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *selectedAccountId = [preferences objectForKey:[Account preferenceKeySelectedAccount]];

    if (selectedAccountId.length == 0)
        selectedAccountId = Account.demoId;

    // Fetch Account model values

    NSString *urlSettings = nil;
    NSString *loginSettings = nil;
    NSString *passwordSettings = nil;

    NSArray *accountList = [ModelsDataController fetchAccounts];

    for (Account *account in accountList) {
        if ([selectedAccountId isEqualToString:account.id]) {
            urlSettings = account.url;
            loginSettings = account.login;
            passwordSettings = account.password;
        }
    }

    // Demo values

    if ((urlSettings == nil) || (urlSettings.length == 0)) {
        urlSettings = @"parapheur.demonstrations.adullact.org";
        loginSettings = @"bma";
        passwordSettings = @"secret";
    }

    // Init

    [self initRestClientWithLogin:loginSettings
                         password:passwordSettings
                              url:urlSettings];

    return self;
}


- (void)initRestClientWithLogin:(NSString *)login
                       password:(NSString *)password
                            url:(NSString *)url {

    // Fix values

    if (![url hasPrefix:@"https://m."])
        url = [NSString stringWithFormat:@"https://m-%@", url];

    // Initialize AFNetworking HTTPClient

    if (_swiftManager)
        [_swiftManager cancelAllOperations];

    _swiftManager = [RestClient.alloc initWithBaseUrl:url
                                                login:login
                                             password:password];
}


- (void)cancelAllHTTPOperationsWithPath:(NSString *)path {

//	[_swiftManager.manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
//		[self cancelTasksInArray:dataTasks
//		                withPath:path];
//		[self cancelTasksInArray:uploadTasks
//		                withPath:path];
//		[self cancelTasksInArray:downloadTasks
//		                withPath:path];
//	}];
}


#pragma mark - Requests


- (void)getTypology:(NSString *)bureauId
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

    [_swiftManager getTypologyWithBureauId:bureauId
                                onResponse:^(NSArray *response) {
                                    success(response);
                                }
                                   onError:^(NSError *error) {
                                       failure(error);
                                   }];
}


- (void)getSignInfoForDossier:(Dossier *)dossier
                    andBureau:(NSString *)bureauId
                      success:(void (^)(SignInfo *))success
                      failure:(void (^)(NSError *))failure {

    [self cancelAllHTTPOperationsWithPath:@"getSignInfo"];

    [_swiftManager getSignInfoWithFolder:dossier
                                  bureau:bureauId
                              onResponse:^(SignInfo *response) {
                                   success(response);
                               }
                                 onError:^(NSError *error) {
                                      failure(error);
                                  }];
}


#pragma mark - Simple actions



@end
