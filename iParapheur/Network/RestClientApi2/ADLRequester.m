/*
 * Copyright 2012-2016, Adullact-Projet.
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
#import "ADLRequester.h"
#import "ADLAPIOperation.h"

@implementation ADLRequester

@synthesize lockApi = _lockApi;
@synthesize lockDoc = _lockDoc;

static ADLRequester *sharedRequester = nil;


+ (ADLRequester *)sharedRequester {
    
    if (sharedRequester == nil)
        sharedRequester = [[super allocWithZone:NULL] init];
    return sharedRequester;
}


-(id)init {
    
    if (self = [super init]) {
        downloadQueue = [NSOperationQueue new];
        downloadQueue.name = @"Download Queue";
        downloadQueue.maxConcurrentOperationCount = 1;
        
        apiQueue = [NSOperationQueue new];
        apiQueue.maxConcurrentOperationCount = 5;
        apiQueue.name = @"API Queue";
        
        _lockApi = [NSRecursiveLock new];
        _lockDoc = [NSRecursiveLock new];
    }
    
    return self;
}


-(void) downloadDocumentAt:(NSString*)path
				  delegate:(id<ADLParapheurWallDelegateProtocol>)delegate {
	
    [_lockDoc lock];
    
    // clear download queue.
    // XXX this shouldn't bug the user with messages !
    [downloadQueue cancelAllOperations];
    [downloadQueue waitUntilAllOperationsAreFinished];

    ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
    ADLAPIOperation *downloadOperation = [[ADLAPIOperation alloc] initWithDocumentPath:path
																	andCollectivityDef:def
																			  delegate:delegate];
    [downloadQueue addOperation:downloadOperation];

    [_lockDoc unlock];
}


-(NSData *) downloadDocumentNow: (NSString*)path{
    [downloadQueue cancelAllOperations];

    ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
    ADLAPIOperation *downloadOperation = [[ADLAPIOperation alloc] initWithDocumentPath:path
																	andCollectivityDef:def
																			  delegate:nil];
    [downloadQueue addOperation:downloadOperation];
    
    [downloadQueue waitUntilAllOperationsAreFinished];
    
    NSData *documentData = [[downloadOperation receivedData] copy];

    return documentData;
}


-(void) request:(NSString*)request
		andArgs:(NSDictionary*)args
	   delegate:(id<ADLParapheurWallDelegateProtocol>)delegate {
	
    [_lockApi lock];
    
    NSLog(@"request : %@", request);
    NSLog(@"args : %@", args);
    
    ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
    ADLAPIOperation *apiRequestOperation = [[ADLAPIOperation alloc] initWithRequest:request
																		   withArgs:args
																 andCollectivityDef:def
																		   delegate:delegate];

    [apiQueue addOperation:apiRequestOperation];

    [_lockApi unlock];
}


-(void) request:(NSString*)request
	   delegate:(id<ADLParapheurWallDelegateProtocol>)delegate {
	
    [_lockApi lock];
    
    NSLog(@"%@", request);
    
    ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
    ADLAPIOperation *apiRequestOperation = [[ADLAPIOperation alloc] initWithRequest:request
																	collectivityDef:def
																		   delegate:delegate];
    
    [apiQueue addOperation:apiRequestOperation];
	
    [_lockApi unlock];
}


@end
