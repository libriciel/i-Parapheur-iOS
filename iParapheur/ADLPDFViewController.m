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
//  ADLPDFViewController.m
//  iParapheur
//


#import "ADLPDFViewController.h"
#import "ReaderContentView.h"
#import "LGViewHUD.h"
#import "RGDossierDetailViewController.h"
#import "RGDocumentsView.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLAPIOperation.h"
#import "ADLActionViewController.h"
#import "UIColor+CustomColors.h"
#import "UIColor+CustomColors.h"

#define kActionButtonsWidth 300.0f
#define kActionButtonsHeight 100.0f

@interface ADLPDFViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation ADLPDFViewController
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.hide
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dossierSelected:) name:kDossierSelected object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBatchSelectionChange:) name:kDidBatchSelectionChange object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectBureauAppeared:)
                                                 name:kSelectBureauAppeared object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dossierActionComplete:)
                                                 name:kDossierActionComplete object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDocumentWithIndex:) name:kshowDocumentWithIndex object:nil];
    
    self.navigationItem.rightBarButtonItem = nil;
    //self.navigationItem.leftBarButtonItem = nil;
    self.actions = [NSMutableArray new];
    [self configureView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Reset view state
- (void) resetViewState {
    for(UIView *subview in [self.view subviews]) {
        [subview removeFromSuperview];
    }
    
    [[self navigationController] popToRootViewControllerAnimated:YES];
    
    //self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    //self.navigationItem.leftBarButtonItem = nil;
    
    [_actionPopover dismissPopoverAnimated:YES];
    [_documentsPopover dismissPopoverAnimated:YES];
    _documentsPopover = nil;
    _actionPopover = nil;
    _readerViewController = nil;
    _actionsCollectionView = nil;

}

#pragma mark - selector for observer

- (void) dossierActionComplete: (NSNotification*) notification {
    [self resetViewState];
}

- (void) dossierSelected: (NSNotification*) notification {
    NSString *dossierRef = [notification object];
    _dossierRef = dossierRef;
    
    
    for(UIView *subview in [self.view subviews]) {
        [subview removeFromSuperview];
    }
    
    LGViewHUD *hud = [LGViewHUD defaultHUD];
    hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
    hud.topText=@"";
    hud.bottomText=@"Chargement ...";
    hud.activityIndicatorOn=YES;
    [hud setDelegate:self];
    [hud showInView:self.view];
    
    API_GETDOSSIER(dossierRef, [[ADLSingletonState sharedSingletonState] bureauCourant]);
    API_GETANNOTATIONS(dossierRef, [[ADLSingletonState sharedSingletonState] bureauCourant]);
    
    
    NSArray *buttons = [[NSArray alloc] initWithObjects:_actionButton, _detailsButton, _documentsButton, nil];
    
    //self.navigationItem.leftBarButtonItem = _documentsButton;
    self.navigationItem.rightBarButtonItems = buttons;
    
    [[self navigationController] popToRootViewControllerAnimated:YES];

}


- (void) didBatchSelectionChange:(NSNotification*)notification {
    NSArray *oldActions = [NSArray arrayWithArray:self.actions];

    if (((NSArray*) notification.object).count == 0) {
        [self resetViewState];
    }
    else {
        if (!self.actionsCollectionView) {
            [self resetViewState];
            UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
            self.actionsCollectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) / 2.0f - kActionButtonsWidth / 2, kActionButtonsHeight / 2, kActionButtonsWidth, CGRectGetHeight(self.view.frame) - kActionButtonsHeight / 2) collectionViewLayout:layout];
            [self.actionsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"actionCell"];

            self.actionsCollectionView.backgroundColor = [UIColor clearColor];
            self.actionsCollectionView.delegate = self;
            self.actionsCollectionView.dataSource = self;
            
            [self.view addSubview:self.actionsCollectionView];
        }
        
        [self.actionsCollectionView performBatchUpdates:
         ^{
             self.actions = [NSMutableArray arrayWithArray:notification.object];
             NSArray *toDelete = [oldActions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.actions]];
             NSArray *toAdd = [self.actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", oldActions]];
             NSMutableArray *deletePaths = [[NSMutableArray alloc] initWithCapacity:toDelete.count];
             NSMutableArray *addPaths = [[NSMutableArray alloc] initWithCapacity:toAdd.count];
             for (NSString *action in toDelete) {
                 [deletePaths addObject:[NSIndexPath indexPathForRow:[oldActions indexOfObject:action] inSection:0]];
             }
             for (int i = 0; i < toAdd.count; i++) {
                 [addPaths addObject:[NSIndexPath indexPathForRow:(oldActions.count - toDelete.count + i) inSection:0]];
             }
             [self.actionsCollectionView deleteItemsAtIndexPaths:deletePaths];
             [self.actionsCollectionView insertItemsAtIndexPaths:addPaths];
         } completion:nil];
    }
}

-(void) selectBureauAppeared:(NSNotification*) notification {
    [self resetViewState];
}

-(void) showDocumentWithIndex:(NSNotification*) notification {
    NSNumber* docIndex = [notification object];
    [self displayDocumentAt:[docIndex integerValue]];
    [_documentsPopover dismissPopoverAnimated:YES];
    _documentsPopover = nil;
    
}


#pragma mark - Wall delegate Implementation
-(void) displayDocumentAt: (NSInteger) index {
    NSDictionary *document = [[_dossier objectForKey:@"documents" ] objectAtIndex:index];
    
    LGViewHUD *hud = [LGViewHUD defaultHUD];
    hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
    hud.topText=@"";
    hud.bottomText=@"Chargement ...";
    hud.activityIndicatorOn=YES;
    
    [hud showInView:self.view];
    
    _isDocumentPrincipal = index == 0;
    
    ADLRequester *requester = [ADLRequester sharedRequester];
        
    
    /* Si le document n'a pas de visuelPdf on suppose que le document est en PDF */
    if ([document objectForKey:@"visuelPdfUrl"] != nil) {
        [requester downloadDocumentAt:[document objectForKey:@"visuelPdfUrl"] delegate:self];
    }
    else if ([document objectForKey:@"downloadUrl"] != nil) {
        [requester downloadDocumentAt:[document objectForKey:@"downloadUrl"] delegate:self];
    }
}

-(void)didEndWithRequestAnswer:(NSDictionary*)answer {
    NSString *s = [answer objectForKey:@"_req"];
    [[LGViewHUD defaultHUD] setHidden:YES];

    if ([s isEqual:GETDOSSIER_API]) {
        _dossier = [answer copy];
        [self displayDocumentAt: 0];
        
        self.navigationController.navigationBar.topItem.title = [_dossier objectForKey:@"titre"];
        
        NSString *documentPrincipal = [[[_dossier objectForKey:@"documents"] objectAtIndex:0] objectForKey:@"downloadUrl"];
        [[ADLSingletonState sharedSingletonState] setCurrentPrincipalDocPath:documentPrincipal];
        NSLog(@"%@", [_dossier objectForKey:@"actions"]);
        
        if ([[[_dossier objectForKey:@"actions"] objectForKey:@"sign"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            if ([[_dossier objectForKey:@"actionDemandee"] isEqualToString:@"SIGNATURE"]) {
                NSDictionary *signInfoArgs = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:_dossierRef], @"dossiers", nil];
                ADLRequester *requester = [ADLRequester sharedRequester];
                [requester request:@"getSignInfo" andArgs:signInfoArgs delegate:self];
            }
            else {
                _visaEnabled = YES;
                _signatureFormat = nil;
            }
        }

        LGViewHUD *hud = [LGViewHUD defaultHUD];
        hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
        hud.topText=@"";
        hud.bottomText=@"Chargement ...";
        hud.activityIndicatorOn=YES;

        [hud showInView:self.view];
    
    }
    else if ([s isEqualToString:@"getSignInfo"]) {
        _signatureFormat = [[[answer objectForKey:_dossierRef] objectForKey:@"format"] copy];
    }
    else if ([s isEqualToString:GETANNOTATIONS_API]) {
        NSArray *annotations = [[answer objectForKey:@"annotations"] copy];
        
        _annotations = annotations;
        
        for (NSNumber *contentViewIdx in [_readerViewController contentViews]) {
            [[[[_readerViewController contentViews] objectForKey:contentViewIdx] contentPage] refreshAnnotations];
        }

    }

    else if ([s isEqualToString:@"addAnnotation"]) {
        ADLRequester *requester = [ADLRequester sharedRequester];
        
        NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                              _dossierRef,
                              @"dossier",
                              nil];
        
        [requester request:GETANNOTATIONS_API andArgs:args delegate:self];
                
    }
    
}

- (void)didEndWithUnReachableNetwork {
    
}

- (void)didEndWithUnAuthorizedAccess {
    
}


- (void)didEndWithDocument:(ADLDocument*)document {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSFileHandle *file;
    
    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
	NSString *docPath = [documentsPaths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"myfile.bin"];
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    
    file = [NSFileHandle fileHandleForWritingAtPath: filePath];
    [file writeData:[document documentData]];
    
    
    ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:filePath password:nil];
    

    
    _readerViewController = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
    
    [_readerViewController setDataSource:self];
    
    
    [_readerViewController setAnnotationsEnabled:_isDocumentPrincipal];
    
    
    _readerViewController.delegate = self;
    _readerViewController.view.frame = [[self view] frame];
    
    [_readerViewController.view setAutoresizingMask:( UIViewAutoresizingFlexibleWidth |
                                                 UIViewAutoresizingFlexibleHeight )];
    [[self view] setAutoresizesSubviews:YES];
    
    for(UIView *subview in [self.view subviews]) {
        [subview removeFromSuperview];
    }

    [[self view] addSubview:[_readerViewController view]];
     
    [[LGViewHUD defaultHUD] setHidden:YES];
    
    ADLRequester *requester = [ADLRequester sharedRequester];
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          _dossierRef,
                          @"dossier",
                          nil];
    
    [requester request:GETANNOTATIONS_API andArgs:args delegate:self];

    LGViewHUD *hud = [LGViewHUD defaultHUD];
    hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
    hud.topText=@"";
    hud.bottomText=@"Chargement ...";
    hud.activityIndicatorOn=YES;
    
    [hud showInView:self.view];

}


- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
#if (DEMO_VIEW_CONTROLLER_PUSH == TRUE)
    
	[self.navigationController popViewControllerAnimated:YES];
    
#else // dismiss the modal view controller
    
	[self dismissViewControllerAnimated:YES completion:nil];
    
#endif // DEMO_VIEW_CONTROLLER_PUSH
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
   
 
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_readerViewController updateScrollViewContentViews];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"dossierDetails"]) {
        [((RGDossierDetailViewController*) [segue destinationViewController]) setDossier:_dossier];
    }
    
    if ([[segue identifier] isEqualToString:@"showDocumentPopover"]) {
        [((RGDocumentsView*)[segue destinationViewController]) setDocuments:[_dossier objectForKey:@"documents"]];
        if (_documentsPopover != nil) {
            [_documentsPopover dismissPopoverAnimated:NO];
        }
        
        _documentsPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
        [_documentsPopover setDelegate:self];

    }
    
    if ([[segue identifier] isEqualToString:@"showActionPopover"]) {
        if (_actionPopover != nil) {
            [_actionPopover dismissPopoverAnimated:NO];
        }
        
        _actionPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
        
        // do something usefull there
        if ([_signatureFormat isEqualToString:@"CMS"]) {
            [((ADLActionViewController*)[_actionPopover contentViewController]) setSignatureEnabled:YES];
        }
        else if (_visaEnabled) {
            [((ADLActionViewController*)[_actionPopover contentViewController]) setVisaEnabled:YES];
        }
        
        [_actionPopover setDelegate:self];
        
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if (_documentsPopover != nil && _documentsPopover == popoverController) {
        _documentsPopover = nil;
    }
    else if (_actionPopover != nil && _actionPopover == popoverController) {
        _actionPopover = nil;
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - Annotations Drawing view data Source

-(NSArray*) annotationsForPage:(NSInteger)page {
    NSMutableArray *annotsAtPage = [[NSMutableArray alloc] init];
    for (NSDictionary *etape in _annotations) {
        NSArray *annotationsAtPageForEtape = [etape objectForKey:[NSString stringWithFormat:@"%d", page]];
        
        if (annotationsAtPageForEtape != nil && [annotationsAtPageForEtape count] > 0) {
            [annotsAtPage addObjectsFromArray:annotationsAtPageForEtape];
        }
    }
    
    return annotsAtPage;
}


-(void) updateAnnotation:(ADLAnnotation*)annotation forPage:(NSUInteger)page {
    NSDictionary *dict = [annotation dict];
    NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithUnsignedInteger:page], @"page",
                         dict, @"annotation",
                         [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
                         , nil];
    
    ADLRequester *requester = [ADLRequester sharedRequester];
    [requester request:@"updateAnnotation" andArgs:req delegate:self];
}

-(void) removeAnnotation:(ADLAnnotation*)annotation {
       NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:
                         [annotation uuid], @"uuid",
                            [NSNumber numberWithUnsignedInt:10], @"page",
                         [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
                         , nil];
    
    ADLRequester *requester = [ADLRequester sharedRequester];
    
    [requester request:@"removeAnnotation" andArgs:req delegate:self];

}

-(void) addAnnotation:(ADLAnnotation*)annotation forPage:(NSUInteger)page {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[annotation dict]];
    [dict setValue: [NSNumber numberWithUnsignedInteger:page] forKey:@"page"];
    NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:
                        
                         [NSArray arrayWithObjects:dict, nil], @"annotations",
                         [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
                         , nil];
    
    ADLRequester *requester = [ADLRequester sharedRequester];
    [requester request:@"addAnnotation" andArgs:req delegate:self];
    
    
}

-(void)shallDismissHUD:(LGViewHUD*)hud {
    [hud hideWithAnimation:HUDAnimationHideFadeOut];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Dossiers", @"Dossiers");
    barButtonItem.tintColor = [UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f];
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark UICollectionViewDelegate protocol implementation (used in batch mode)


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kActionButtonsWidth, kActionButtonsHeight);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kActionButtonsHeight / 2;
}

/*- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0f;
}*/



#pragma mark UICollectionViewDataSource protocol implementation (used in batch mode)

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.actions.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"actionCell" forIndexPath:indexPath];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(cell.frame), CGRectGetHeight(cell.frame))];
    NSString *action = [self.actions objectAtIndex:indexPath.row];
    
    [button setTitle:action forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorForAction:action];
    
    [button addTarget:self action:[self actionFromString:action] forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:button];
    return cell;
}

-(SEL) actionFromString:(NSString*) action {
    if ([action isEqualToString:@"SIGNER"]) {
        return @selector(batchSign);
    }
    else if ([action isEqualToString:@"VISER"]) {
        return @selector(batchVisa);
    }
    else if ([action isEqualToString:@"REJETER"]) {
        return @selector(batchReject);
    }
    return @selector(batchUnknown);
}

-(void) batchSign {
    NSLog(@"SIGNATURE");
}

-(void) batchVisa {
    NSLog(@"VISA");
}

-(void) batchReject {
    NSLog(@"REJET");
}

-(void) batchUnknown {
    NSLog(@"INCONNU");
}


@end
