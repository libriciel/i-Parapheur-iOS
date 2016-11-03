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

import Foundation
import AFNetworking

@objc class RestClientApiV3: NSObject {

    let kCFURLErrorBadServerResponse = -1011
    var manager: AFHTTPSessionManager

    // MARK: - Constructor

    init(baseUrl: NSString,
         login: NSString,
         password: NSString) {

        manager = AFHTTPSessionManager(baseURL: NSURL(string: RestClientApiV3.cleanupServerName(baseUrl) as String))
        manager.requestSerializer = AFJSONRequestSerializer() // force serializer to use JSON encoding
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(login as String, password: password as String);
        manager.setSessionDidReceiveAuthenticationChallengeBlock {
            (session, challenge, credential) -> NSURLSessionAuthChallengeDisposition in

            // shouldTrustProtectionSpace will evaluate the challenge using bundled certificates, and set a value into credential if it succeeds
            if RestClientApiV3.shouldTrustProtectionSpace(challenge, credential: credential) {
                return NSURLSessionAuthChallengeDisposition.UseCredential
            }

            return NSURLSessionAuthChallengeDisposition.PerformDefaultHandling
        }

		// GET needs a JSONResponseSerializer,
		// POST/PUT/DELETE needs an HTTPResponseSerializer

		let compoundResponseSerializer = AFCompoundResponseSerializer.compoundSerializerWithResponseSerializers([AFJSONResponseSerializer(),
                                                                                                                 AFHTTPResponseSerializer()])
		manager.responseSerializer = compoundResponseSerializer

    }

    // MARK: - Static methods

    class func cleanupServerName(url: NSString) -> NSString {

        // Removing space
        // TODO Adrien : add special character restrictions tests ?

        var urlFixed = url.mutableCopy()
        urlFixed = urlFixed.stringByReplacingOccurrencesOfString(" ", withString: "")

        // Getting the server name
        // Regex :	- ignore everything before "://" (if exists)					^(?:.*:\/\/)*
        //			- then ignore following "m." (if exists)						(?:m\.)*
        //			- then catch every char but "/"									([^\/]*)
        //			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
        let regex: NSRegularExpression = try! NSRegularExpression(pattern: "^(?:.*:\\/\\/)*(?:m\\.)*([^\\/]*)(?:\\/.*)*$",
                                                                  options: NSRegularExpressionOptions.CaseInsensitive)

        let match: NSTextCheckingResult? = regex.firstMatchInString(urlFixed as! String,
                                                                   options: NSMatchingOptions.Anchored,
                                                                   range: NSMakeRange(0, urlFixed.length))

        if (match != nil) {
			urlFixed = urlFixed.substringWithRange(match!.rangeAtIndex(1))
		}
		
        return NSString(string: "https://m.\(urlFixed)")
    }

    class func shouldTrustProtectionSpace(challenge: NSURLAuthenticationChallenge,
                                          credential: AutoreleasingUnsafeMutablePointer<NSURLCredential?>) -> Bool {

        // note: credential is a reference; any created credential should be sent back using credential.memory

        let protectionSpace: NSURLProtectionSpace = challenge.protectionSpace
        var trust: SecTrustRef = protectionSpace.serverTrust!

        // load the root CA bundled with the app
        let certPath: String? = NSBundle.mainBundle().pathForResource("acmobile", ofType: "der")
        if (certPath == nil) {
            print("Certificate does not exist!")
            return false
        }

        let certData: NSData = NSData(contentsOfFile: certPath!)!
        let cert: SecCertificateRef? = SecCertificateCreateWithData(kCFAllocatorDefault, certData)

        if (cert == nil) {
            print("Certificate data could not be loaded. DER format?")
            return false
        }

        // create a policy that ignores hostname
        let domain: CFString? = nil
        let policy: SecPolicy = SecPolicyCreateSSL(true, domain)

        // takes all certificates from existing trust
        let numCerts = SecTrustGetCertificateCount(trust)
        var certs: [SecCertificateRef] = [SecCertificateRef]()
        for i in 0 ..< numCerts {
            // takeUnretainedValue
            let c: SecCertificateRef? = SecTrustGetCertificateAtIndex(trust, i)
            certs.append(c!)
        }

        // and adds them to the new policy
        var newTrust: SecTrust? = nil
        var err: OSStatus = SecTrustCreateWithCertificates(certs, policy, &newTrust)
        if (err != noErr) {
            print("Could not create trust")
        }

        // TakeUnretainedValue
        trust = newTrust! // replace old trust

        // set root cert
        let rootCerts: [AnyObject] = [cert!]
        err = SecTrustSetAnchorCertificates(trust, rootCerts)

        // evaluate the certificate and product a trustResult
        var trustResult: SecTrustResultType = SecTrustResultType()
        SecTrustEvaluate(trust, &trustResult)

        if (Int(trustResult) == Int(kSecTrustResultProceed) || Int(trustResult) == Int(kSecTrustResultUnspecified)) {
            // create the credential to be used
            credential.memory = NSURLCredential(trust: trust)
            return true
        }

        return false
    }

    class func parsePageAnnotations(pages: [String:AnyObject],
                                    step: Int,
                                    documentId: String) -> [Annotation] {

        var parsedAnnotations = [Annotation]()

        for page in pages {

            if let jsonAnnotations = page.1 as? [[String:AnyObject]] {
                for jsonAnnotation in jsonAnnotations {

                    let annotation = Annotation(json: jsonAnnotation)
                    annotation!.step = step
                    annotation!.page = Int(page.0)
                    annotation!.documentId = documentId

                    parsedAnnotations.append(annotation!)
                }
            }
        }

        return parsedAnnotations
    }

    // MARK: - Get methods

    func getApiVersion(onResponse: ((NSNumber) -> Void)?,
                       onError: ((NSError) -> Void)?) {

        manager.GET("/parapheur/api/getApiLevel",
                    parameters: nil,
                    success: {
                        (task: NSURLSessionDataTask!, responseObject: AnyObject!) in

                        guard let apiLevel = ApiLevel(json: responseObject as! [String: AnyObject])
                        else {
                            onError!(NSError(domain: self.manager.baseURL!.absoluteString, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                            return
                        }

						onResponse!(NSNumber(integer: apiLevel.level!))
                    },
                    failure: {
                        (task: NSURLSessionDataTask!, error: NSError!) in
                        onError!(error)
                    })
    }

    func getBureaux(onResponse: ((NSArray) -> Void)?,
                    onError: ((NSError) -> Void)?) {

        manager.GET("/parapheur/bureaux",
                    parameters: nil,
                    success: {
                        (task: NSURLSessionDataTask!, responseObject: AnyObject!) in

                        let bureauList = [Bureau].fromJSONArray(responseObject as! [[String: AnyObject]])
                        if (bureauList!.count == 0) {
                            onError!(NSError(domain: self.manager.baseURL!.absoluteString, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                            return
                        }

                        onResponse!(bureauList!)
                    },
                    failure: {
                        (task: NSURLSessionDataTask!, error: NSError!) in
                        onError!(error)
                    })
    }

    func getDossiers(bureau: NSString,
                     page: NSNumber,
                     size: NSNumber,
                     filterJson: NSString?,
                     onResponse: ((NSArray) -> Void)?,
                     onError: ((NSError) -> Void)?) {

        // Parameters

        let paramsDict: NSMutableDictionary = NSMutableDictionary()
        paramsDict["asc"] = true
        paramsDict["bureau"] = bureau
        paramsDict["page"] = page
        paramsDict["pageSize"] = size
        paramsDict["pendingFile"] = 0
        paramsDict["skipped"] = Double(page) * (Double(size) - 1)
        paramsDict["sort"] = "cm:create"

        if (filterJson != nil) {
            paramsDict["filter"] = filterJson
        }

        // Request

        manager.GET("/parapheur/dossiers",
                    parameters: paramsDict,
                    success: {
                        (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
						let dossierList = [Dossier].fromJSONArray(responseObject as! [[String: AnyObject]])
                        onResponse!(dossierList!)
                    },
                    failure: {
                        (task: NSURLSessionDataTask!, error: NSError!) in
                        onError!(error)
                    })
    }

    func getDossier(dossier: NSString,
                    bureau: NSString,
                    onResponse: ((Dossier) -> Void)?,
                    onError: ((NSError) -> Void)?) {

        // Parameters

        let paramsDict: NSMutableDictionary = NSMutableDictionary()
        paramsDict["bureauCourant"] = bureau

        // Request

        manager.GET("/parapheur/dossiers/\(dossier)",
                    parameters: paramsDict,
                    success: {
                         (task: NSURLSessionDataTask!, responseObject: AnyObject!) in

                         guard let responseDossier = Dossier(json: responseObject as! [String: AnyObject])
                         else {
                             onError!(NSError(domain: self.manager.baseURL!.absoluteString, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                             return
                         }

                        onResponse!(responseDossier)
                     },
                    failure: {
                         (task: NSURLSessionDataTask!, error: NSError!) in
                         onError!(error)
                     })
    }

    func getCircuit(dossier: NSString,
                    onResponse: ((AnyObject) -> Void)?,
                    onError: ((NSError) -> Void)?) {

        manager.GET("/parapheur/dossiers/\(dossier)/circuit",
                    parameters: nil,
                    success: {
                         (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                         onResponse!(responseObject)
                     },
                    failure: {
                         (task: NSURLSessionDataTask!, error: NSError!) in
                         onError!(error)
                     })
    }

    func getTypology(bureauId: NSString,
                     onResponse: ((NSArray) -> Void)?,
                     onError: ((NSError) -> Void)?) {

//        // Parameters
//
//        let paramsDict: NSMutableDictionary = NSMutableDictionary()
//        paramsDict["asc"] = true
//        paramsDict["bureau"] = bureau

        // Request

        manager.GET("/parapheur/types",
                    parameters: nil,
                    success: {
                        (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                        let typeList = [ParapheurType].fromJSONArray(responseObject as! [[String: AnyObject]])
                        onResponse!(typeList!)
                    },
                    failure: {
                        (task: NSURLSessionDataTask!, error: NSError!) in
                        onError!(error)
                    })
    }

    func getAnnotations(dossier: NSString,
                        onResponse: (([Annotation]) -> Void)?,
                        onError: ((NSError) -> Void)?) {

        manager.GET("/parapheur/dossiers/\(dossier)/annotations",
                    parameters: nil,
                    success: {
                        (task: NSURLSessionDataTask!, responseObject: AnyObject!) in

                        // Parse

                        var parsedAnnotations = [Annotation]()

                        if let etapes = responseObject as? [AnyObject] {
                            for etapeIndex in 0 ..< etapes.count {

                                if let documentPages = etapes[etapeIndex] as? [String:AnyObject] {

                                    for documentPage in documentPages {
                                        if let pages = documentPage.1 as? [String:AnyObject] {

                                            // Parsing API4
                                            parsedAnnotations += RestClientApiV3.parsePageAnnotations(pages,
                                                                                                      step: etapeIndex,
                                                                                                      documentId: documentPage.0 as String)
                                        }
                                    }

                                    // Parsing API3
                                    parsedAnnotations += RestClientApiV3.parsePageAnnotations(documentPages,
                                                                                              step: etapeIndex,
                                                                                              documentId: "*")
                                }
                            }
                        }
                        else {
                            onError!(NSError(domain: self.manager.baseURL!.absoluteString, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                            return
                        }

                        onResponse!(parsedAnnotations)
                    },
                    failure: {
                        (task: NSURLSessionDataTask!, error: NSError!) in
                        onError!(error)
                    })
    }

    func getSignInfo(dossier: NSString,
                     bureau: NSString,
                     onResponse: ((AnyObject) -> Void)?,
                     onError: ((NSError) -> Void)?) {

        // Parameters

        let paramsDict: NSMutableDictionary = NSMutableDictionary()
        paramsDict["bureauCourant"] = bureau

        // Request

        manager.GET("/parapheur/dossiers/\(dossier)/getSignInfo",
                    parameters: paramsDict,
                    success: {
                         (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                         onResponse!(responseObject)
                     },
                    failure: {
                         (task: NSURLSessionDataTask!, error: NSError!) in
                         onError!(error)
                     })
    }

    func sendSimpleAction(type: NSNumber,
                          url: NSString,
                          args: NSDictionary,
                          onResponse: ((AnyObject) -> Void)?,
                          onError: ((NSError) -> Void)?) {

        if (type == 1) {

            manager.POST(url as String,
                         parameters: args,
                         success: {
                              (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                              onResponse!(1)
                          },
                         failure: {
                              (task: NSURLSessionDataTask!, error: NSError!) in
                              onError!(error)
                         })
        }
        else if (type == 2) {

            manager.PUT(url as String,
                        parameters: args,
                        success: {
                             (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                             onResponse!(1)
                         },
                        failure: {
                             (task: NSURLSessionDataTask!, error: NSError!) in
                             onError!(error)
                         })
        }
        else if (type == 3) {

            manager.DELETE(url as String,
                           parameters: args,
                           success: {
                                (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
                                onResponse!(1)
                            },
                           failure: {
                                (task: NSURLSessionDataTask!, error: NSError!) in
                                onError!(error)
                            })
        }
    }
}

