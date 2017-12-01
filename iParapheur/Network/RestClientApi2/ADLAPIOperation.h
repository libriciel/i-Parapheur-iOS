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
#import <Foundation/Foundation.h>
#import "ADLParapheurWallDelegateProtocol.h"
#import "ADLCollectivityDef.h"


@interface ADLAPIOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
	BOOL downloadingDocument;
	BOOL get;
	NSURLConnection *_connection;
}

@property(nonatomic, strong) NSString *documentPath;
@property(nonatomic, strong) NSString *request;
@property(nonatomic, strong) NSDictionary *args;

@property(readonly) BOOL isExecuting;
@property(readonly) BOOL isFinished;

@property(nonatomic, strong) NSMutableData *receivedData;
@property(nonatomic, strong) NSString *mimeType;
@property(nonatomic, strong) ADLCollectivityDef *collectivityDef;
@property(nonatomic, strong) NSObject <ADLParapheurWallDelegateProtocol> *delegate;
@property(readwrite, nonatomic, strong) NSRecursiveLock *lock;


- (id)initWithDocumentPath:(NSString *)documentPath
        andCollectivityDef:(ADLCollectivityDef *)def
                  delegate:(id <ADLParapheurWallDelegateProtocol>)delegate;

- (id)initWithRequest:(NSString *)request
             withArgs:(NSDictionary *)args
   andCollectivityDef:(ADLCollectivityDef *)def
             delegate:(id <ADLParapheurWallDelegateProtocol>)delegate;

- (id)initWithRequest:(NSString *)request
      collectivityDef:(ADLCollectivityDef *)def
             delegate:(id <ADLParapheurWallDelegateProtocol>)delegate;


/*
-(BOOL) isConcurrent;
-(BOOL) isExecuting;
-(BOOL) isFinished;
-(BOOL) isCancelled;
-(BOOL) isReady;
 */
@end


