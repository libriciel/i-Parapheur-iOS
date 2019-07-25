/*
 * Contributors : SKROBS (2012)
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
#import "ADLPDFViewController.h"
#import "ReaderContentView.h"
#import "ReaderContentPage.h"
#import "RGDossierDetailViewController.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "iParapheur-Swift.h"
#import "RGWorkflowDialogViewController.h"


@interface ADLPDFViewController () <ReaderViewControllerDelegate>

@end


@implementation ADLPDFViewController


#pragma mark - UIViewController


- (void)viewDidLoad {

    [super viewDidLoad];
    NSLog(@"View loaded : ADLPDFViewController");

    self.definesPresentationContext = true;
    [self deleteEveryBinFile];
    self.navigationItem.rightBarButtonItems = @[];

    // Build UI

    self.navigationController.navigationBar.tintColor = ColorUtils.Aqua;
    self.navigationItem.rightBarButtonItem = nil;

    if (UIDevice.currentDevice.systemVersion.floatValue > 8.0) {
        UISplitViewController *uiSplitView = (UISplitViewController *) UIApplication.sharedApplication.delegate.window.rootViewController;
        UIBarButtonItem *backButton = uiSplitView.displayModeButtonItem;

        self.navigationItem.leftBarButtonItem = backButton;
        self.navigationItem.leftItemsSupplementBackButton = YES;

        @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [backButton.target performSelector:backButton.action];
#pragma clang diagnostic pop
        }
        @catch (NSException *e) {}
    }

    _restClient = ADLRestClient.sharedManager;
}


- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    // Notifications register

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(dossierSelected:)
                                               name:kDossierSelected
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(clearDetail:)
                                               name:kSelectBureauAppeared
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(clearDetail:)
                                               name:WorkflowDialogController.ACTION_COMPLETE
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(clearDetail:)
                                               name:kFilterChanged
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(showDocumentWithIndex:)
                                               name:DocumentSelectionController.NotifShowDocument
                                             object:nil];

    //

    [self.navigationController setNavigationBarHidden:NO
                                             animated:animated];
}


- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    else
        return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // [_readerViewController updateScrollViewContentViews];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

    if ([segue.identifier isEqualToString:@"dossierDetails"]) {

        ((RGDossierDetailViewController *) segue.destinationViewController).dossierRef = _dossierRef;
        // FIXME ((RGDossierDetailViewController *) segue.destinationViewController).dossierRef = _currentDesk;
    } else if ([segue.identifier isEqualToString:@"showDocumentPopover"]) {

        ((DocumentSelectionController *) segue.destinationViewController).documentList = _dossier.documents;
        if (_documentsPopover != nil)
            [_documentsPopover dismissViewControllerAnimated:NO completion:nil];

        _documentsPopover = segue.destinationViewController;

    } else if ([segue.identifier isEqualToString:ActionSelectionController.SEGUE]) {

        if (_actionPopover != nil)
            [_actionPopover dismissViewControllerAnimated:NO completion:nil];

        _actionPopover = segue.destinationViewController;
        ((ActionSelectionController *) _actionPopover).currentDossier = _dossier;
        ((ActionSelectionController *) _actionPopover).delegate = self;

        if ([_signatureFormat isEqualToString:@"CMS"])
            ((ActionSelectionController *) _actionPopover).signatureEnabled = @1;
        else if (_visaEnabled)
            ((ActionSelectionController *) _actionPopover).visaEnabled = @1;

    } else if ([segue.identifier isEqualToString:WorkflowDialogController.SEGUE]) {
        WorkflowDialogController *controller = ((WorkflowDialogController *) segue.destinationViewController);
        controller.currentAction = sender;
        controller.restClient = _restClient.restClientApi.swiftManager;
        //FIXME  [controller setDossiersToSignWithObjcArray:@[_dossier]];
        controller.currentBureau = [ADLSingletonState.sharedSingletonState.bureauCourant stringByReplacingOccurrencesOfString:@"workspace://SpacesStore/"
                                                                                                                   withString:@""];
    }
}


- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


#pragma mark - ReaderViewControllerDelegate methods


- (void)dismissReaderViewController:(ReaderViewController *)viewController {

    _readerViewController.delegate = nil;
    _readerViewController.dataSource = nil;
    [_readerViewController willMoveToParentViewController:nil];
    [_readerViewController.view removeFromSuperview];
    [_readerViewController removeFromParentViewController];
    _readerViewController = nil;
}


#pragma mark - ADLDrawingViewDataSource


- (NSArray *)annotationsForPage:(NSInteger)page {

    // Get current step

    int currentStep = 0;

    if (_circuit && (_circuit.count > 0)) {
        for (NSUInteger i = 0; i < _circuit.count; i++) {

            Circuit *circuit = _circuit[i];
            NSArray *steps = circuit.etapes;
            for (NSUInteger j = 0; j < steps.count; j++) {

                Etape *step = steps[j];
                if (step.approved) {
                    // If this step was approved, the current step might be the next one
                    currentStep = j + 1;
                }
            }
        }
    }

    // Updating annotations

    for (Annotation *annotation in _annotations) {
        bool isEditable = (annotation.step >= currentStep);
        annotation.editable = isEditable;
    }

    // Filtering annotations

    NSArray *result = [_annotations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {

        bool isPage = ((Annotation *) object).page == page;
        bool isDoc = [((Annotation *) object).identifier isEqualToString:_document.identifier];
        bool isApi3 = [((Annotation *) object).identifier isEqualToString:@"*"];

        return isPage && (isDoc || isApi3);
    }]];

    return result;
}


- (void)updateAnnotation:(Annotation *)annotation {

    [_restClient updateAnnotation:annotation
                       forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
                          success:^(NSArray *result) {
                              NSLog(@"updateAnnotation success");
                          }
                          failure:^(NSError *error) {
                              [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
                                                       title:@"Erreur à la sauvegarde de l'annotation"];
                          }];
}


- (void)removeAnnotation:(Annotation *)annotation {

    [_restClient removeAnnotation:annotation
                       forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
                          success:^(NSArray *result) {
                              NSLog(@"deleteAnnotation success");
                          }
                          failure:^(NSError *error) {
                              [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
                                                       title:@"Erreur à la suppression de l'annotation"];
                          }];
}


- (void)addAnnotation:(Annotation *)annotation {

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *selectedAccountId = [preferences objectForKey:[Account PREFERENCE_KEY_SELECTED_ACCOUNT]];

    if (selectedAccountId.length == 0)
        selectedAccountId = Account.DEMO_ID;

    // Fetch Login

    NSString *login = @"";
    NSArray *accountList = [ModelsDataController fetchAccounts];

    for (Account *account in accountList) {
        if ([selectedAccountId isEqualToString:account.id]) {
            login = account.login;
        }
    }

    //

    annotation.author = login;
    annotation.documentId = _document.identifier;

    __weak typeof(self) weakSelf = self;
    [_restClient addAnnotation:annotation
                    forDossier:ADLSingletonState.sharedSingletonState.dossierCourantReference
                       success:^(NSArray *result) {
                           __strong typeof(weakSelf) strongSelf = weakSelf;
                           if (strongSelf) {
                               [strongSelf requestAnnotations];
                           }
                       }
                       failure:^(NSError *error) {
                           [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
                                                    title:@"Erreur à la sauvegarde de l'annotation"];
                       }];
}


#pragma mark - LGViewHUDDelegate


- (void)shallDismissHUD:(LGViewHUD *)hud {

    HIDE_HUD
}


#pragma mark - ADLParapheurWallDelegateProtocol


- (void)getDossierDidEndWithRequestAnswer:(Dossier *)dossier {

    _dossier = dossier;

    // Determine the first pdf file to display

    for (Document *document in dossier.documents) {
        if (document.isVisuelPdf) {
            _document = document;
            break;
        }
    }

    //

    [self displayDocumentAt:0];
    self.navigationController.navigationBar.topItem.title = dossier.title;

    // Refresh buttons

    NSArray *buttons;

    if (dossier.documents.count > 1)
        buttons = @[_actionButton, _documentsButton, _detailsButton];
    else
        buttons = @[_actionButton, _detailsButton];

    self.navigationItem.rightBarButtonItems = buttons;

    [self requestSignInfoForDossier:dossier];
}


#pragma mark - NotificationCenter selectors


- (void)dossierSelected:(NSNotification *)notification {

    NSString *dossierRef = [notification object];

    _dossierRef = dossierRef;

    SHOW_HUD

    __weak typeof(self) weakSelf = self;
    [_restClient getDossier:[ADLSingletonState sharedSingletonState].bureauCourant
                    dossier:_dossierRef
                    success:^(Dossier *result) {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        if (strongSelf) {
                            HIDE_HUD
                            [strongSelf getDossierDidEndWithRequestAnswer:result];
                        }
                    }
                    failure:^(NSError *error) {
                        NSLog(@"getBureau fail : %@", error.localizedDescription);
                    }];

    [_restClient getCircuit:_dossierRef
                    success:^(Circuit *circuit) {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        if (strongSelf) {
                            HIDE_HUD
                            strongSelf.circuit = @[circuit].mutableCopy;
                            //[strongSelf requestAnnotations];
                        }
                    }
                    failure:^(NSError *error) {
                        NSLog(@"getCircuit fail : %@", error.localizedDescription);
                    }];

    //[[self navigationController] popToRootViewControllerAnimated:YES];
}


- (void)showDocumentWithIndex:(NSNotification *)notification {

    NSNumber *docIndex = notification.object;
    [self displayDocumentAt:docIndex.integerValue];
    [_documentsPopover dismissViewControllerAnimated:YES completion:nil];
    _documentsPopover = nil;
}


- (void)clearDetail:(NSNotification *)notification {

    [self dismissReaderViewController:_readerViewController];

    // Hide title

    self.navigationController.navigationBar.topItem.title = nil;

    // Hide Buttons

    NSArray *buttons = @[];
    self.navigationItem.rightBarButtonItems = buttons;

    // Hide popovers

    if (_documentsPopover != nil)
        [_documentsPopover dismissViewControllerAnimated:NO completion:nil];

    if (_actionPopover != nil)
        [_actionPopover dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - Private methods


- (void)deleteEveryBinFile {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //here everything you want to perform in background

        // The preferred way to get the apps documents directory

        NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = documentsPaths[0];

        // Grab all the files in the documents dir

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:docDirectory
                                                             error:nil];

        // Filter the array for only bin files

        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.bin'"];
        NSArray *binFiles = [allFiles filteredArrayUsingPredicate:fltr];

        // Use fast enumeration to iterate the array and delete the files

        for (NSString *binFile in binFiles) {
            NSError *error = nil;
            [fileManager removeItemAtPath:[docDirectory stringByAppendingPathComponent:binFile]
                                    error:&error];
        }
    });
}


- (NSURL *)getFileUrlWithDossierRef:(NSString *)dossierId
                    andDocumentName:(NSString *)documentName {

    NSURL *documentsDirectoryURL = [NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory
                                                                        inDomain:NSUserDomainMask
                                                               appropriateForURL:nil
                                                                          create:YES
                                                                           error:nil];

    NSString *cleanedName = [documentName stringByReplacingOccurrencesOfString:@" "
                                                                    withString:@"_"];
    NSString *fileName = [NSString stringWithFormat:@"%@.bin",
                                                    cleanedName];

    documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:@"dossiers" isDirectory:true];
    [NSFileManager.defaultManager createDirectoryAtPath:documentsDirectoryURL.absoluteString
                                             attributes:nil];

    documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:dossierId isDirectory:true];
    [NSFileManager.defaultManager createDirectoryAtPath:documentsDirectoryURL.absoluteString
                                             attributes:nil];

    documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:fileName];

    return documentsDirectoryURL;
}


- (void)requestAnnotations {

    NSString *documentId = _document.identifier;

    __weak typeof(self) weakSelf = self;
    [_restClient getAnnotations:_dossierRef
                       document:documentId
                        success:^(NSArray *annotations) {

                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            if (strongSelf) {
                                strongSelf.annotations = annotations;

                                for (NSNumber *contentViewIdx in strongSelf.readerViewController.getContentViews) {
                                    ReaderContentView *currentReaderContentView = strongSelf.readerViewController.getContentViews[contentViewIdx];
                                    [currentReaderContentView.getContentPage refreshAnnotations];
                                }
                            }
                        }
                        failure:^(NSError *error) {
                            NSLog(@"getAnnotations error");
                        }];
}


- (void)requestSignInfoForDossier:(Dossier *)dossier {

    if ([dossier.actions containsObject:@"SIGNATURE"]) {
        if ([dossier.actionDemandee isEqualToString:@"SIGNATURE"]) {
            __weak typeof(self) weakSelf = self;
            [_restClient getSignInfoForDossier:dossier
                                     andBureau:ADLSingletonState.sharedSingletonState.bureauCourant
                                       success:^(SignInfo *signInfo) {
                                           __strong typeof(weakSelf) strongSelf = weakSelf;
                                           if (strongSelf) {
                                               strongSelf.signatureFormat = signInfo.format;
                                           }
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"getSignInfo %@", error.localizedDescription);
                                       }];
        } else {
            _visaEnabled = YES;
            _signatureFormat = nil;
        }
    }
}


- (void)loadPdfAt:(NSString *)filePath {

    _readerDocument = [ReaderDocument withDocumentFilePath:filePath
                                                  password:nil];

    if (_readerDocument != nil) // Must have a valid ReaderDocument object in order to proceed with things
    {
        // Deleting previous child controller

        _readerViewController.delegate = nil;
        _readerViewController.dataSource = nil;
        [_readerViewController willMoveToParentViewController:nil];
        [_readerViewController.view removeFromSuperview];
        [_readerViewController removeFromParentViewController];
        _readerViewController = nil;

        // Creating new child controller

        _readerViewController = [[ReaderViewController alloc] initWithReaderDocument:_readerDocument];
        _readerViewController.delegate = self;
        _readerViewController.dataSource = self;
        _readerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        _readerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self.view setAutoresizesSubviews:YES];
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

        [self addChildViewController:_readerViewController];
        [self.view addSubview:_readerViewController.view];
    } else {    // Log an error so that we know that something went wrong
        NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:nil] failed.", __FUNCTION__, filePath);
    }
}


- (void)displayDocumentAt:(NSInteger)index {

    _document = _dossier.documents[(NSUInteger) index];

    // File cache

    NSURL *filePath = [self getFileUrlWithDossierRef:_document.identifier
                                     andDocumentName:_document.name];

    if ([NSFileManager.defaultManager fileExistsAtPath:filePath.path]) {

        NSLog(@"PDF : Cached data");

        [self loadPdfAt:filePath.path];
        [self requestAnnotations];

        return;
    }

    // Downloading files

    NSLog(@"PDF : Download data");

    SHOW_HUD

    if (_dossier.documents) {
        bool isPdf = (bool) _document.isVisuelPdf;

        [_restClient downloadDocument:_document.identifier
                                isPdf:isPdf
                               atPath:filePath
                              success:^(NSString *string) {
                                  HIDE_HUD
                                  [self loadPdfAt:string];
                                  [self requestAnnotations];
                              }
                              failure:^(NSError *error) {
                                  HIDE_HUD
                                  [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
                                                           title:nil];
                              }];
    }
}


// <editor-fold desc="ActionSelectionControllerDelegate">

- (void)onActionSelectedWithAction:(NSString *)action {
    [self performSegueWithIdentifier:WorkflowDialogController.SEGUE
                              sender:action];
}

// </editor-fold desc="ActionSelectionControllerDelegate">


@end
