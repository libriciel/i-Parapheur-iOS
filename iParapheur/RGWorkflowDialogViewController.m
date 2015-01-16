/*
 * Version 1.1
 * CeCILL Copyright (c) 2012, SKROBS, ADULLACT-projet
 * Initiated by ADULLACT-projet S.A.
 * Developped by SKROBS
 *
 * contact@adullact-projet.coop
 *
 * Ce logiciel est un programme informatique servant à faire circuler des
 * documents au travers d'un circuit de validation, où chaque acteur vise
 * le dossier, jusqu'à l'étape finale de signature.
 *
 * Ce logiciel est régi par la licence CeCILL soumise au droit français et
 * respectant les principes de diffusion des logiciels libres. Vous pouvez
 * utiliser, modifier et/ou redistribuer ce programme sous les conditions
 * de la licence CeCILL telle que diffusée par le CEA, le CNRS et l'INRIA
 * sur le site "http://www.cecill.info".
 *
 * En contrepartie de l'accessibilité au code source et des droits de copie,
 * de modification et de redistribution accordés par cette licence, il n'est
 * offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
 * seule une responsabilité restreinte pèse sur l'auteur du programme,  le
 * titulaire des droits patrimoniaux et les concédants successifs.
 *
 * A cet égard  l'attention de l'utilisateur est attirée sur les risques
 * associés au chargement,  à l'utilisation,  à la modification et/ou au
 * développement et à la reproduction du logiciel par l'utilisateur étant
 * donné sa spécificité de logiciel libre, qui peut le rendre complexe à
 * manipuler et qui le réserve donc à des développeurs et des professionnels
 * avertis possédant  des  connaissances  informatiques approfondies.  Les
 * utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
 * logiciel à leurs besoins dans des conditions permettant d'assurer la
 * sécurité de leurs systèmes et ou de leurs données et, plus généralement,
 * à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.
 *
 * Le fait que vous puissiez accéder à cet en-tête signifie que vous avez
 * pris connaissance de la licence CeCILL, et que vous en avez accepté les
 * termes.
 */

//
//  RGWorkflowDialogViewController.m
//  iParapheur
//
//

#import "RGWorkflowDialogViewController.h"
#import "ADLCollectivityDef.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "RGAppDelegate.h"
#import "ADLPasswordAlertView.h"
#import "ADLRequester.h"
#import "ADLAPIHelper.h"
#import "PrivateKey.h"
#import "LGViewHUD.h"
#import <NSData+Base64/NSData+Base64.h>
#import <AJNotificationView/AJNotificationView.h>

@interface RGWorkflowDialogViewController ()


@end


@implementation RGWorkflowDialogViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGWorkflowDialogViewController");

	_restClient = [[ADLRestClient alloc] init];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationBar.topItem.title = [ADLAPIHelper actionNameForAction:self.action];
	if ([self.action isEqualToString:@"SIGNER"]) {
		[self.navigationBar.topItem.rightBarButtonItem setEnabled:NO];
	}
	else {
		[self.certificateLabel setHidden:YES];
		[self.certificatesTableView setHidden:YES];
		if ([self.action isEqualToString:@"REJETER"]) {
			self.annotationPubliqueLabel.text = @"Motif de rejet (obligatoire)";
		}
	}
	ADLKeyStore *keystore = [((RGAppDelegate*)[[UIApplication sharedApplication] delegate]) keyStore];
	
	self.pkeys = [keystore listPrivateKeys];
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


- (IBAction)finish:(id)sender {
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	NSMutableDictionary *args = [[NSMutableDictionary alloc]
								 initWithObjectsAndKeys:
								 self.dossiersRef, @"dossiers",
								 [self.annotationPublique text], @"annotPub",
								 [self.annotationPrivee text], @"annotPriv",
								 [[ADLSingletonState sharedSingletonState] bureauCourant], @"bureauCourant",
								 nil];

	if ([self.action isEqualToString:@"VISER"]) {
		[self showHud];
		
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
			for (NSString* dossierRef in _dossiersRef) {
				[_restClient actionViserForDossier:dossierRef
										 forBureau:[[ADLSingletonState sharedSingletonState] bureauCourant]
							  withPublicAnnotation:[self.annotationPublique text]
							 withPrivateAnnotation:[self.annotationPrivee text]
										   success:^(NSArray *result) {
											   NSLog(@"Adrien actionViser success : %@", result);
											   [self dismissDialogView];
										   }
										   failure:^(NSError *error) {
											   NSLog(@"actionViser error : %@", error.localizedDescription);
											   //Adrien TODO check error or 200
											   [self dismissDialogView];
										   }];
			}
		}
		else {
			[requester request:@"visa" andArgs:args delegate:self];
		}
	}
	else if ([self.action isEqualToString:@"SECRETARIAT"]) {
		[self showHud];
		[requester request:@"secretariat" andArgs:args delegate:self];
	}
	else if ([self.action isEqualToString:@"REJETER"]) {
		if (self.annotationPublique.text && (self.annotationPublique.text.length > 0)) {
			[self showHud];
			[requester request:@"reject" andArgs:args delegate:self];
		}
		else {
			[[[UIAlertView alloc] initWithTitle:@"Attention" message:@"Veuillez saisir le motif de votre rejet" delegate:nil cancelButtonTitle:@"Fermer" otherButtonTitles:nil] show];
		}
		
	}
	else if ([self.action isEqualToString:@"SIGNER"]) {
		// create signatures array
		PrivateKey *pkey = _currentPKey;
		
		/* Ask for pkey password */
		
		ADLPasswordAlertView *alertView =
		[[ADLPasswordAlertView alloc] initWithTitle:@"Déverrouillage de la clef privée"
											message:[NSString
													 stringWithFormat:@"Entez le mot de passe pour %@",
													 [[pkey p12Filename] lastPathComponent]]
										   delegate:self cancelButtonTitle:@"Annuler"
								  otherButtonTitles:@"Confirmer", nil];
		
		alertView.p12Path = [pkey p12Filename];
		
		[alertView show];
		
		
	}
	
	// [args release];
	
}


- (IBAction)cancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void) showHud {
	LGViewHUD *hud = [LGViewHUD defaultHUD];
	hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
	hud.topText=@"";
	hud.bottomText=@"Chargement ...";
	hud.activityIndicatorOn=YES;
	[hud showInView:self.view];
}


- (void) hideHud {
	LGViewHUD *hud = [LGViewHUD defaultHUD];
	[hud hideWithAnimation:HUDAnimationHideFadeOut];
}


-(void)dismissDialogView {
	[self hideHud];
	[self dismissViewControllerAnimated:YES completion:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDossierActionComplete object:nil];
}


-(void) didEndWithRequestAnswer:(NSDictionary *)answer {
	NSLog(@"MIKAF %@", answer);
	
	if ([[answer objectForKey:@"_req"] isEqualToString:@"getSignInfo"]) {
		// get selected dossiers for some sign info action :)
		
		NSMutableArray *hashes = [[NSMutableArray alloc] init];
		NSMutableArray *dossiers = [[NSMutableArray alloc] init];
		NSMutableArray *signatures = [[NSMutableArray alloc] init];
		
		for (NSString *dossier in self.dossiersRef) {
			NSDictionary *signInfo = [answer objectForKey:dossier];
			
			if ([[signInfo objectForKey:@"format"] isEqualToString:@"CMS"]) {
				[dossiers addObject:dossier];
				[hashes addObject:[signInfo objectForKey:@"hash"]];
			}
			
		}
		
		ADLKeyStore *keystore = [((RGAppDelegate*)[[UIApplication sharedApplication] delegate]) keyStore];
		
		PrivateKey *pkey = _currentPKey;
		
		NSError *error = nil;
		
		
		for (NSString *hash in hashes) {
			NSData *hash_data = [keystore bytesFromHexString:hash];
			error = nil;
			NSData *signature = [keystore PKCS7Sign:[pkey p12Filename]
									   withPassword:[self p12password]
											andData:hash_data
											  error:&error];
			
			if (signature == nil && error != nil) {
				[AJNotificationView showNoticeInView:self.view
												type:AJNotificationTypeRed
											   title:[NSString stringWithFormat:@"Une erreur s'est produite lors de la signature"]
									 linedBackground:AJLinedBackgroundTypeStatic
										   hideAfter:2.5f];
				NSLog(@"%@", error);
				break;
			}
			else {
				NSString *b64EncodedSignature = [signature base64EncodedString];
				[signatures addObject:b64EncodedSignature];
			}
			
		}
		
		if ([signatures count] > 0 && [signatures count] == [hashes count] && [dossiers count] == [hashes count]) {
			NSMutableDictionary *args = [[NSMutableDictionary alloc]
										 initWithObjectsAndKeys:
										 dossiers, @"dossiers",
										 [self.annotationPublique text], @"annotPub",
										 [self.annotationPrivee text], @"annotPriv",
										 [[ADLSingletonState sharedSingletonState] bureauCourant], @"bureauCourant",
										 signatures, @"signatures",
										 nil];
			
			NSLog(@"%@", args);
			ADLRequester *requester = [ADLRequester sharedRequester];
			
			[self showHud];
			
			NSLog(@"Adrien SIGNATURE = %@", args);
			
			// TODO Adrien : rebranch [requester request:@"signature" andArgs:args delegate:self];
		}
	}
	else  {
		[self hideHud];
		[self dismissViewControllerAnimated:YES completion:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDossierActionComplete object:nil];
	}
	
}


//-(void) didEndWithUnAuthorizedAccess {
//
//}
//

-(void) didEndWithUnReachableNetwork {
	[[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Une erreur est survenue lors de l'envoi de la requête" delegate:nil cancelButtonTitle:@"Fermer" otherButtonTitles: nil] show];
}


#pragma mark - UITableView Datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _pkeys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"PKeyCell"];
	
	if(cell == nil) {
		cell = [[UITableViewCell alloc] init];
	}
	
	PrivateKey *pkey = [_pkeys objectAtIndex:[indexPath row]];
	
	[[cell textLabel] setText:[pkey commonName]];
	
	
	return cell;
}


#pragma mark - UITableView delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// we selected a private key now fetching it
	
	_currentPKey = [_pkeys objectAtIndex:(NSUInteger)[indexPath row]];
	
	// now we have a pkey we can activate Sign Button
	[self.navigationBar.topItem.rightBarButtonItem setEnabled:YES];
}


#pragma mark - UIAlertView delegate


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		UITextField *passwordTextField = [alertView textFieldAtIndex:0];
		[self setP12password:[passwordTextField text]];
		
		ADLRequester *requester = [ADLRequester sharedRequester];
		NSDictionary *signInfoArgs = [NSDictionary dictionaryWithObjectsAndKeys:[self dossiersRef], @"dossiers", nil];
		[requester request:@"getSignInfo" andArgs:signInfoArgs delegate:self];
		
		
	}
}

@end
