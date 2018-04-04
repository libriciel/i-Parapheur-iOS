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
#import "RGAppDelegate.h"
#import "PrivateKey.h"
#import "ADLCertificateAlertView.h"
#import "ADLRestClient.h"
#import "StringUtils.h"
#import "iParapheur-Swift.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


#define RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT 1
#define RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE 2

@implementation RGAppDelegate

@synthesize window = _window;
@synthesize splitViewController = _splitViewController;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize keyStore = _keyStore;


#pragma mark - Life cycle


- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[Fabric with:@[Crashlytics.class]];

	NSLog(@"Adrien = Application did launch");
	[self checkP12FilesInLocalDirectory];

	// Override point for customization after application launch.
//	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//		UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//		UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//		splitViewController.delegate = (id)navigationController.topViewController;
//		NSLog(@"delegate : %@", [(id)navigationController.topViewController description]);
//	}

	NSArray *keys = self.keyStore.listPrivateKeys;
	for (PrivateKey *pkey in keys) {
		NSLog(@"commonName %@", pkey.commonName);
		NSLog(@"caName %@", pkey.caName);
		NSLog(@"p12Filename %@", pkey.p12Filename);
		NSString *cert = [NSString.alloc initWithData:pkey.publicKey
		                                     encoding:NSUTF8StringEncoding];
		NSLog(@"certData %@", cert);
	}

	// UI overrode parameters

	[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor = [UIColor lightGrayColor];

	//

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	//  API_LOGIN([[NSUserDefaults standardUserDefaults] stringForKey:@"settings_login"], [[NSUserDefaults standardUserDefaults] stringForKey:@"settings_password"]);
}


#pragma mark - Core Data stack

/**
 * Returns the managed object context for the application.
 * If the context doesn't already exist,
 * it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {

	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}

	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		_managedObjectContext = [NSManagedObjectContext new];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return _managedObjectContext;
}

/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {

	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}

	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"KeyStore"
	                                          withExtension:@"momd"];
	NSLog(@"%@", modelURL);

	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

	return _managedObjectModel;
}

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}

	NSURL *storeURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:@"keystore.sqlite"];

	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	NSDictionary *options = @{
			NSMigratePersistentStoresAutomaticallyOption: @YES,
			NSInferMappingModelAutomaticallyOption: @YES
	};
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
	                                               configuration:nil
	                                                         URL:storeURL
	                                                     options:options
	                                                       error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible;
		 * The schema for the persistent store is incompatible with current managed object model.
		 Check the error message to determine what the actual problem was.

		 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
		 
		 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
		 * Simply deleting the existing store:
		 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
		 
		 * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
		 @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
		 
		 Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
		 
		 */
		NSLog(@"%@", storeURL);
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
		abort();
	}

	return _persistentStoreCoordinator;
}

#pragma mark - Scheme link


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

	// Open With

	if ([url.scheme isEqualToString:@"file"]) {
		NSLog(@"Adrien given file : %@", url);
		[CryptoUtils moveCertificateWithUrl:url];
		[self checkP12FilesInLocalDirectory];
		return YES;
	}

	// Scheme

    if ([InController parseIntentWithUrl:url]) {
        return YES;
    }

	NSDictionary *importCertifArguments = [self parseImportCertificateArgumentsFromUrl:url];
	if (importCertifArguments) {

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		ADLRestClient *restClient = ADLRestClient.sharedManager;
		NSString *certifUrl = importCertifArguments[@"iOsUrl"];
		NSString *certifPwd = importCertifArguments[@"iOsPwd"];
		NSError *downloadError = [restClient downloadCertificateUrlWithUrl:certifUrl
		                                                            onPath:paths[0]];

		if (!downloadError) {
			if (certifPwd) {
				NSArray *p12Docs = [self importableP12Stores];

				for (NSString *p12store in p12Docs) {
					if ([p12store.lastPathComponent isEqualToString:certifUrl.lastPathComponent]) {

						[self importCertificate:p12store
						           withPassword:certifPwd];
					}
				}
			}
			else {
				[self checkP12FilesInLocalDirectory];
			}
		} else {
			[ViewUtils logErrorWithMessage:downloadError.localizedDescription
									 title:@"Erreur au téléchargement du certificat"];
		}

		return NO;
	}
	
	return YES;
}

/**
 * Parsing the given parameters.
 * This parsing takes a bit of code, and would be easier in iOS8.
 * TODO : Use simplest NSURLComponents, when iOS7 support will be dropped
 *
 * Waiting arguments like :
 *
 * iparapheur://importCertificate?iOsUrl=https://url/certif.p12             (mandatory)
 *                                &iOsPwd=pwd                               (optional)
 *                                &AndroidUrl=https://url/certif.bks        (ignored)
 *                                &AndroidPassword=pwd                      (ignored)
 */
- (NSDictionary *)parseImportCertificateArgumentsFromUrl:(NSURL *)url {

	NSString *urlString = url.absoluteString;

	// Regex :	- should start with iparapheur://					                 ^iparapheur:\/\/
	//			- followed with action name, and a ?	    				         importCertificate\?
	//			- then, catching the first group, non greedy						 ([^&]*)=(.*?)
	//          - then, any other group, if exists, till the end of line (max 3)     (?:&([^&]*)=(.*?))?    => 3 times
	NSString *importCertifPattern = @"^iparapheur:\\/\\/importCertificate\\?([^&]*)=(.*?)(?:&([^&]*)=(.*?))?(?:&([^&]*)=(.*?))?(?:&([^&]*)=(.*?))?$";

	NSRegularExpression *isImportCertifRegex = [NSRegularExpression regularExpressionWithPattern:importCertifPattern
	                                                                                     options:NSRegularExpressionCaseInsensitive
	                                                                                       error:nil];

	NSArray *matches = [isImportCertifRegex matchesInString:urlString
	                                                options:0
	                                                  range:NSMakeRange(0, urlString.length)];

	// Default case

	if (!matches.count) {
		NSLog(@"Pattern \"%@\" doesn't match string \"%@\"", importCertifPattern, urlString);
		return nil;
	}

	// Parsing arguments

	NSString *certificateUrl;
	NSString *certificatePassword;
	NSTextCheckingResult *firstMatch = matches[0];

	// Careful there, there is a (i+2) loop.
	// That's weird, but we need to parse couples of key/values, and it ease things with the crappy iOS regex system.
	for (NSUInteger i = 1; i < (firstMatch.numberOfRanges - 1); i = i+2) {
		NSRange range = [firstMatch rangeAtIndex:i];

		// iOS 9.1 poor regex system returns wrong values/length on variable groups catched.
		// If the regex can catch 6 groups max, but only capture 4, the remaining 2 will make the entire OS crash on rangeAtIndex.
		if ((range.length > urlString.length) || (range.location > urlString.length))
			break;

		NSString *subString = [urlString substringWithRange:range];
		NSRange nextRange = [firstMatch rangeAtIndex:(i + 1)];
		NSString *nextSubString = [urlString substringWithRange:nextRange];

		if ([subString isEqualToString:@"iOsUrl"])
			certificateUrl = [StringUtils decodeUrlString:nextSubString];
		else if ([subString isEqualToString:@"iOsPwd"])
			certificatePassword = [StringUtils decodeUrlString:nextSubString];
	}

	// Build result

	NSMutableDictionary *result = NSMutableDictionary.new;

	if (certificateUrl)
		result[@"iOsUrl"] = certificateUrl;
	if (certificatePassword)
		result[@"iOsPwd"] = certificatePassword;

	return result;
}

#pragma mark - Application Documents directory

/**
 * Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {

	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
	                                               inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Private methods


- (void)checkP12FilesInLocalDirectory {

	NSArray *p12Docs = [self importableP12Stores];
	NSLog(@"Adrien importables p12 : %@", p12Docs);

	for (NSString *p12Path in p12Docs) {
		NSLog(@"p12Path :%@", p12Docs);

		NSString *message = [NSString stringWithFormat:@"Entrez le mot de passe pour %@", p12Path.lastPathComponent];
		ADLCertificateAlertView *alertView = [ADLCertificateAlertView.alloc initWithTitle:@"Importer le certificat"
																				  message:message
																				 delegate:self
																		cancelButtonTitle:@"Annuler"
																		otherButtonTitles:@"Confirmer", nil];

		alertView.p12Path = p12Path;
		alertView.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT;
		[alertView show];
	}
}


- (NSMutableArray *)importableP12Stores {

	NSMutableArray *retval = NSMutableArray.array;
	NSURL *certificateFolder = [CryptoUtils getCertificateTempDirectory];
	NSString *certificateFolderPath = certificateFolder.path;

	NSError *error;
	NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:certificateFolderPath
	                                                                   error:&error];

	NSLog(@"Adrien certificateFolderPath -- %@", certificateFolderPath);
	NSLog(@"Adrien    -> %@", files);

	if (files == nil) {
		NSLog(@"Error reading contents of documents directory: %@", error.localizedDescription);
		return retval;
	}

	for (NSString *file in files) {
		NSLog(@"Adrien -- %@", file);
		
		if (([file.pathExtension compare:@"p12"
		                         options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
				([file.pathExtension compare:@"pfx"
				                     options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
			NSString *fullPath = [certificateFolderPath stringByAppendingPathComponent:file];
			[retval addObject:fullPath];
		}
	}

	return retval;
}


- (void)importCertificate:(NSString *)certificatePath
			 withPassword:(NSString *)password {

	NSError *error = nil;

	BOOL success = [_keyStore addKey:certificatePath
	                    withPassword:password
	                           error:&error];

	if ((!success) || (error != nil)) {

		// Retry on error
		if (error.code == P12OpenErrorCode) {
			NSString *message = [NSString stringWithFormat:@"Entrez le mot de passe pour %@", certificatePath.lastPathComponent];

			ADLCertificateAlertView *realert = [ADLCertificateAlertView.alloc initWithTitle:@"Erreur de mot de passe"
                                                                                    message:message
                                                                                   delegate:self
                                                                          cancelButtonTitle:@"Annuler"
                                                                          otherButtonTitles:@"Confirmer", nil];

			realert.p12Path = certificatePath;
			realert.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT;
			[realert show];
		}
		else if (error.code == P12AlreadyImported) {

			[ViewUtils logWarningWithMessage:certificatePath.lastPathComponent
									   title:@"Ce fichier de certificat a déjà été importé."];

			[self deleteCertificate:certificatePath];
		}

		NSLog(@"error %@", error.localizedDescription);
	}
	else {
		[ViewUtils logSuccessWithMessage:@"Ce certificat a bien été importé."
		                                  title:certificatePath.lastPathComponent];
	}
}


- (void)deleteCertificate:(NSString *)certificatePath {

	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	[fileManager removeItemAtPath:certificatePath
	                        error:&error];

	if (!error) {
		[ViewUtils logInfoWithMessage:certificatePath.lastPathComponent
		                               title:@"Ce fichier de certificat a été supprimé."];
	} else {
		[ViewUtils logErrorWithMessage:error.localizedDescription
		                                title:@"Erreur à la suppression du fichier"];
	}
}


#pragma mark - KeyStore


- (ADLKeyStore *)keyStore {

	if (_keyStore == nil) {
		_keyStore = ADLKeyStore.new;
		_keyStore.managedObjectContext = self.managedObjectContext;
		[_keyStore checkUpdates];
	}

	return _keyStore;
}


#pragma mark - Button listener


- (void)   alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {

	ADLCertificateAlertView *pwdAlertView = (ADLCertificateAlertView *) alertView;

	if (alertView.tag == RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT) {
		if (buttonIndex == 1) {
			UITextField *passwordTextField = [alertView textFieldAtIndex:0];

			[self importCertificate:pwdAlertView.p12Path
			           withPassword:passwordTextField.text];
		}
		else {
			ADLCertificateAlertView *realert = [[ADLCertificateAlertView alloc] initWithTitle:@"Voulez-vous supprimer ce certificat ?"
			                                                                          message:pwdAlertView.p12Path.lastPathComponent
			                                                                         delegate:self
			                                                                cancelButtonTitle:@"Annuler"
			                                                                otherButtonTitles:@"Confirmer", nil];

			realert.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE;
			realert.p12Path = pwdAlertView.p12Path;
			realert.alertViewStyle = UIAlertViewStyleDefault;
			[realert show];
		}
	}
	else if (alertView.tag == RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE) {
		if (buttonIndex == 1)
			[self deleteCertificate:pwdAlertView.p12Path];
	}
}


@end
