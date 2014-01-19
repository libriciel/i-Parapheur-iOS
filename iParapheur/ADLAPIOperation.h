//
//  ADLAPIDocumentOperation.h
//  iParapheur
//
//  Created by Emmanuel Peralta on 10/12/12.
//
//

#import <Foundation/Foundation.h>
#import "ADLParapheurWallDelegateProtocol.h"
#import "ADLCollectivityDef.h"
#import "JSONKit.h"


@interface ADLAPIOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    BOOL downloadingDocument;
    BOOL get;
    NSURLConnection *_connection;
}
@property (nonatomic, strong) NSString *documentPath;
@property (nonatomic, strong) NSString *request;
@property (nonatomic, strong) NSDictionary *args;

@property(readonly) BOOL isExecuting;
@property(readonly) BOOL isFinished;

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) ADLCollectivityDef* collectivityDef;
@property (nonatomic, strong) NSObject<ADLParapheurWallDelegateProtocol> *delegate;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;



-(id)initWithDocumentPath:(NSString *)documentPath andCollectivityDef:(ADLCollectivityDef*)def delegate:(id<ADLParapheurWallDelegateProtocol>)delegate;
-(id)initWithRequest:(NSString*)request withArgs:(NSDictionary*)args andCollectivityDef:(ADLCollectivityDef*)def delegate:(id<ADLParapheurWallDelegateProtocol>)delegate;
-(id)initWithRequest:(NSString *)request collectivityDef:(ADLCollectivityDef*)def delegate:(id<ADLParapheurWallDelegateProtocol>)delegate;

/*
-(BOOL) isConcurrent;
-(BOOL) isExecuting;
-(BOOL) isFinished;
-(BOOL) isCancelled;
-(BOOL) isReady;
 */
@end


