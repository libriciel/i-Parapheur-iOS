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
#import "ADLAPIOperation.h"
#import "SCNetworkReachability/SCNetworkReachability.h"
#import "ADLCredentialVault.h"
#import "iParapheur-Swift.h"


@interface ADLAPIOperation ()

@property(assign) BOOL isExecuting;
@property(assign) BOOL isFinished;
@end


@implementation ADLAPIOperation


#pragma mark - Network Thread


+ (void)networkRequestThreadEntryPoint:(id)object {

	do {
		[NSRunLoop.currentRunLoop run];
	} while (YES);
}


+ (NSThread *)networkRequestThread {

	static NSThread *_networkRequestThread = nil;
	static dispatch_once_t oncePredicate;

	dispatch_once(&oncePredicate, ^{
		_networkRequestThread = [[NSThread alloc] initWithTarget:self
		                                                selector:@selector(networkRequestThreadEntryPoint:)
		                                                  object:nil];
		_networkRequestThread.name = @"Network Request Thread";
		[_networkRequestThread start];
	});

	return _networkRequestThread;
}


- (id)initWithDocumentPath:(NSString *)documentPath
        andCollectivityDef:(ADLCollectivityDef *)def
                  delegate:(id <ADLParapheurWallDelegateProtocol>)delegate {

	if (self = [super init]) {
		_documentPath = documentPath;
		downloadingDocument = YES;
		get = YES;
		_collectivityDef = def;
		_isExecuting = NO;
		_isFinished = NO;
		_delegate = delegate;
	}

	return self;
}


- (id)initWithRequest:(NSString *)request
             withArgs:(NSDictionary *)args
   andCollectivityDef:(ADLCollectivityDef *)def
             delegate:(id <ADLParapheurWallDelegateProtocol>)delegate {

	if (self = [super init]) {
		_request = request;
		_args = args;
		_collectivityDef = def;
		downloadingDocument = NO;
		get = NO;
		_delegate = delegate;
		_isExecuting = NO;
		_isFinished = NO;
	}
	return self;
}


- (id)initWithRequest:(NSString *)request
      collectivityDef:(ADLCollectivityDef *)def
             delegate:(id <ADLParapheurWallDelegateProtocol>)delegate {

	if (self = [super init]) {
		_request = request;
		_collectivityDef = def;
		downloadingDocument = NO;
		get = YES;
		_delegate = delegate;
		_isExecuting = NO;
		_isFinished = NO;
	}
	return self;
}


- (void)start {

	[self performSelector:@selector(startFetching)
	             onThread:[[self class] networkRequestThread]
	           withObject:nil
	        waitUntilDone:NO];
}


- (void)startFetching {

	if ([self isCancelled]) {
		[self setIsFinished:YES];
		[self setIsExecuting:NO];
		return;
	}

	[self setIsExecuting:YES];

	__weak typeof(self) weakSelf = self;
	[SCNetworkReachability host:@"www.apple.com"
	         reachabilityStatus:^(SCNetworkStatus status) {

		         __strong typeof(weakSelf) strongSelf = weakSelf;
		         if (strongSelf) {
			         switch (status) {
				         case SCNetworkStatusReachableViaWiFi:
				         case SCNetworkStatusReachableViaCellular: {

					         ADLCredentialVault *vault = ADLCredentialVault.sharedCredentialVault;
					         NSString *alf_ticket = [vault getTicketForHost:_collectivityDef.host
					                                            andUsername:_collectivityDef.username];
					         NSURL *requestURL = nil;

					         if (alf_ticket != nil) {

						         if (downloadingDocument)
							         requestURL = [NSURL.alloc initWithString:[NSString stringWithFormat:DOWNLOAD_DOCUMENT_URL_PATTERN,
							                                                                             _collectivityDef.host,
							                                                                             _documentPath,
							                                                                             alf_ticket]];
						         else
							         requestURL = [NSURL.alloc initWithString:[NSString stringWithFormat:AUTH_API_URL_PATTERN,
							                                                                             _collectivityDef.host,
							                                                                             _request,
							                                                                             alf_ticket]];
					         } else {
						         //login or programming error
						         requestURL = [NSURL.alloc initWithString:[NSString stringWithFormat:API_URL_PATTERN,
						                                                                             _collectivityDef.host,
						                                                                             _request]];
					         }

					         NSLog(@"%@", requestURL);

					         NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:requestURL];

					         if (downloadingDocument) {
						         [request setHTTPMethod:@"GET"];
					         } else {
						         if (get) {
							         [request setHTTPMethod:@"GET"];
						         } else {
							         [request setHTTPMethod:@"POST"];
							         NSError *error = [NSError errorWithDomain:NSURLErrorDomain
							                                              code:nil
							                                          userInfo:nil];
							         [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:_args
							                                                              options:0
							                                                                error:&error]];
						         }

						         [request setValue:@"application/json"
						        forHTTPHeaderField:@"Content-Type"];

						         [request setValue:@"gzip"
						        forHTTPHeaderField:@"Accept-Encoding"];
					         }

					         NSURLConnection *connection = [NSURLConnection.alloc initWithRequest:request
					                                                                     delegate:strongSelf
					                                                             startImmediately:NO];

					         [connection scheduleInRunLoop:NSRunLoop.currentRunLoop
					                               forMode:NSDefaultRunLoopMode];

					         _receivedData = NSMutableData.data;
					         [connection start];
					         break;
				         }
				         case SCNetworkStatusNotReachable: {
					         if (_delegate && [_delegate respondsToSelector:@selector(didEndWithUnReachableNetwork)])
						         [_delegate didEndWithUnReachableNetwork];
					         break;
				         }
			         }
		         }
	         }];
}


#pragma mark - Connection Delegate for server trust evaluation.


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {

	if (!self.isCancelled) {
		if (_delegate && [_delegate respondsToSelector:@selector(didEndWithUnReachableNetwork)]) {
			[_delegate performSelectorOnMainThread:@selector(didEndWithUnReachableNetwork)
			                            withObject:nil
			                         waitUntilDone:YES];
		} else {
			[ViewUtils logErrorWithMessage:error.localizedDescription
			                         title:nil
			                viewController:nil];
		}
	}

	self.isExecuting = NO;
	self.isFinished = YES;
	[connection cancel];
	_receivedData = nil;

}


- (SecCertificateRef)certificateFromFile:(NSString *)file {

	CFDataRef adullact_g3_ca_data = (__bridge CFDataRef) [NSFileManager.defaultManager contentsAtPath:file];

	return SecCertificateCreateWithData(kCFAllocatorDefault, adullact_g3_ca_data);
}


- (void)                       connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge; {

#ifndef DEBUG_NO_SERVER_TRUST
	SecTrustRef trust = challenge.protectionSpace.serverTrust;
	NSString *adullact_mobile_path = [NSBundle.mainBundle pathForResource:@"acmobile"
	                                                               ofType:@"der"];

	SecCertificateRef adullact_mobile = [self certificateFromFile:adullact_mobile_path];


	//NSArray *anchors = [[NSArray alloc] initWithObjects: (id)adullact_mobile, nil];
	NSArray *anchors = @[(__bridge id) adullact_mobile];

	SecTrustSetAnchorCertificatesOnly(trust, YES);
	//SecTrustSetAnchorCertificates(trust, (CFArrayRef)anchors);
	SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) anchors);

	NSURLCredential *newCredential = nil;

	SecTrustResultType res = kSecTrustResultInvalid;
	OSStatus sanityChesk = SecTrustEvaluate(trust, &res);

#ifdef DEBUG_SERVER_HTTPS
//	for(long i = 0; i < SecTrustGetCertificateCount(trust); i++) {
//		SecCertificateRef cr = SecTrustGetCertificateAtIndex(trust, i);
//		CFStringRef summary = SecCertificateCopySubjectSummary(cr);		
//		NSLog(@"%@", summary);
//	}
#endif

	if (sanityChesk == noErr &&
			(res == kSecTrustResultProceed || res == kSecTrustResultUnspecified)) {

		newCredential = [NSURLCredential credentialForTrust:trust];
		[challenge.sender useCredential:newCredential
		     forAuthenticationChallenge:challenge];
	} else {
		[challenge.sender cancelAuthenticationChallenge:challenge];
	}
#else
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
#endif


}


#pragma mark - Connection delegate for data downloading.


- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {

	if (_mimeType == nil) {
		_mimeType = [response MIMEType];
	}

	if ([(NSHTTPURLResponse *) response statusCode] != 200) {

		if (_delegate && [_delegate respondsToSelector:@selector(didEndWithUnReachableNetwork)])
			[_delegate performSelectorOnMainThread:@selector(didEndWithUnReachableNetwork)
			                            withObject:nil
			                         waitUntilDone:YES];

		[_receivedData setLength:0];
		[self setIsExecuting:NO];
		[self setIsFinished:YES];
		[connection cancel];
		_receivedData = nil;
	}
	//else {

	//NSString *req = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
	//}
}


- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {

	if (![self isCancelled]) {
		[_receivedData appendData:data];
	} else {
		[self setIsExecuting:NO];
		[self setIsFinished:YES];
		[connection cancel];
		_receivedData = nil;
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

	if (downloadingDocument) {
		// trigger downloadedDoc delegate
		if ([_delegate respondsToSelector:@selector(didEndWithDocument:)]) {
			ADLDocument *document = [ADLDocument documentWithData:_receivedData
			                                          AndMimeType:_mimeType];
			[_delegate performSelectorOnMainThread:@selector(didEndWithDocument:)
			                            withObject:document
			                         waitUntilDone:YES];
		}
	} else {
		// trigger api request delegate.
		//[self parseResponse:_receivedData andReq:_request];
		NSError *error = [NSError errorWithDomain:NSArgumentDomain
		                                     code:nil
		                                 userInfo:nil];
		NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:_receivedData
		                                                                      options:NSJSONReadingMutableContainers
		                                                                        error:&error];

		responseObject[@"_req"] = _request;

		if (_delegate && [_delegate respondsToSelector:@selector(didEndWithRequestAnswer:)]) {
			[_delegate performSelectorOnMainThread:@selector(didEndWithRequestAnswer:)
			                            withObject:responseObject
			                         waitUntilDone:NO];
		}
		// [str release];
	}
	[self setIsExecuting:NO];
	[self setIsFinished:YES];
	//[_connection release];
	//[_receivedData release];
}


#pragma mark - automaticaly observer KVO Changes


+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {

	return YES;
}


- (BOOL)isConcurrent {

	return NO;
}


@end
