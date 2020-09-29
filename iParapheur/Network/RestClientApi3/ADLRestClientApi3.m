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
