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
//  RGDocumentsView.m
//  iParapheur
//
//

#import "RGDocumentsView.h"
#import "ADLNotifications.h"


@interface RGDocumentsView ()

@end


@implementation RGDocumentsView

@synthesize documents = _documents;
int numberOfMainDocs;
int numberOfAnnexes;


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil
	                       bundle:nibBundleOrNil];



	return self;
}


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGDocumentsView");

	[self computeSections];
}


- (void)computeSections {

	numberOfMainDocs = 0;
	numberOfAnnexes = 0;

	if ((_documents == nil) || (_documents[0] == nil)) {
		return;
	}

	// Retro-compatibility
	// If the isMainDocument value is missing, then this is before 4.3
	// And the multi-doc is not implemented yet.

	if (_documents[0][@"isMainDocument"] == nil) {
		numberOfMainDocs = 1;
		numberOfAnnexes = (_documents.count - 1);
		return;
	}

	// Default case
	// We search for multiple categories.

	for (NSDictionary *document in _documents) {
		if ([document[@"isMainDocument"] boolValue]) {
			numberOfMainDocs++;
		} else {
			numberOfAnnexes++;
		}
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark - UITableViewDatasource


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	// Init cell

	static NSString *cellIdentifier = @"cellID";
	UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		                              reuseIdentifier:cellIdentifier];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	}

	// Adapt cell

	NSUInteger documentIndex = (NSUInteger)indexPath.row;
	if (indexPath.section == 1) {
		documentIndex = documentIndex + numberOfMainDocs;
	}

	NSDictionary *document = _documents[documentIndex];
	cell.textLabel.text = document[@"name"];

	return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (numberOfAnnexes > 0) ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	return (section == 0) ? numberOfMainDocs : numberOfAnnexes;
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {

	NSString *headerTitle;

	if (section == 0) {
		headerTitle = (numberOfMainDocs <= 1) ? @"Document principal" : @"Documents principaux";
	} else {
		headerTitle = (numberOfAnnexes > 1) ? @"Annexes" : @"Annexe";
	}

	return headerTitle;
}


- (void) tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	int documentIndex = indexPath.row;
	if (indexPath.section == 1) {
		documentIndex = documentIndex + numberOfMainDocs;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:kshowDocumentWithIndex
	                                                    object:@(documentIndex)];
}


#pragma mark -


@end
