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
