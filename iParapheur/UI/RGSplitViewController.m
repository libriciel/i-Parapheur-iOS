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
#import "RGSplitViewController.h"
#import "ADLCredentialVault.h"
#import "ADLRequester.h"

@implementation RGSplitViewController
@synthesize bureauView;


- (void)viewDidLoad {
	[super viewDidLoad];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Requests response


- (void)didEndWithRequestAnswer:(NSDictionary*)answer {
	
	NSString *s = answer[@"_req"];
	
	if ([s isEqual:LOGIN_API]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", @"Alert title when network error happens")
															message:[NSString stringWithFormat:@"%@", answer[@"data"][@"ticket"]]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Alert view dismiss button")
												  otherButtonTitles:nil];
		
		[alertView show];
		//storing ticket ? lacks the host and login information
        //we should add it into the request process ?
        
        ADLCredentialVault *vault = [ADLCredentialVault sharedCredentialVault];
        ADLCollectivityDef *collectivityDef = [ADLCollectivityDef copyDefaultCollectity];
				
        [vault addCredentialForHost:[collectivityDef host]
						   andLogin:[collectivityDef username]
						 withTicket:answer[@"data"][@"ticket"]];
    }
}


- (void)didEndWithUnReachableNetwork {
    
}


- (void)didEndWithUnAuthorizedAccess {
    
}


@end
