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
import Alamofire


@objc class RestClientApiV3: NSObject {

    let kCFURLErrorBadServerResponse = -1011
    var manager: Alamofire.SessionManager
    var serverUrl: NSURL
    var loginHash: String


    // <editor-fold desc="Constructor">


    init(baseUrl: NSString,
         login: NSString,
         password: NSString) {

        manager = AFHTTPSessionManager(baseURL: URL(string: String(RestClientApiV3.cleanupServerName(url: baseUrl))))
        manager.requestSerializer = AFJSONRequestSerializer() // force serializer to use JSON encoding
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(login as String, password: password as String);
        manager.setSessionDidReceiveAuthenticationChallenge {
            (session, challenge, credential) -> URLSession.AuthChallengeDisposition in

            // shouldTrustProtectionSpace will evaluate the challenge using bundled certificates, and set a value into credential if it succeeds
            if RestClientApiV3.shouldTrustProtectionSpace(challenge: challenge, credential: credential!) {
                return URLSession.AuthChallengeDisposition.useCredential
            }

            return URLSession.AuthChallengeDisposition.performDefaultHandling
        }

		// GET needs a JSONResponseSerializer,
		// POST/PUT/DELETE needs an HTTPResponseSerializer

		let compoundResponseSerializer = AFCompoundResponseSerializer.compoundSerializer(withResponseSerializers: [AFJSONResponseSerializer(),
                                                                                                                 AFHTTPResponseSerializer()])
		manager.responseSerializer = compoundResponseSerializer

    }

    // MARK: - Static methods

    class func cleanupServerName(url: NSString) -> NSString {
        var urlFixed = url as String

        // Removing space
        // TODO Adrien : add special character restrictions tests ?
        urlFixed = urlFixed.replacingOccurrences(of: " ", with: "")

        // Getting the server name
        // Regex :	- ignore everything before "://" (if exists)					^(?:.*:\/\/)*
        //			- then ignore following "m." (if exists)						(?:m\.)*
        //			- then catch every char but "/"									([^\/]*)
        //			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
        let regex: NSRegularExpression = try! NSRegularExpression(pattern: "^(?:.*:\\/\\/)*(?:m\\.)*([^\\/]*)(?:\\/.*)*$",
                                                                  options: NSRegularExpression.Options.caseInsensitive)

        let match: NSTextCheckingResult? = regex.firstMatch(in: urlFixed,
                                                            options: NSRegularExpression.MatchingOptions.anchored,
                                                            range: NSMakeRange(0, urlFixed.characters.count))

        if (match != nil) {
            let swiftRange = Range(match!.rangeAt(1), in: urlFixed)
            urlFixed = urlFixed[swiftRange!]
        }

        return NSString(string: "https://m.\(urlFixed)")
    }


//    class func shouldTrustProtectionSpace(challenge: URLAuthenticationChallenge,
//                                          credential: AutoreleasingUnsafeMutablePointer<URLCredential?>) -> Bool {
//
//        // note: credential is a reference; any created credential should be sent back using credential.memory
//
//        let protectionSpace: URLProtectionSpace = challenge.protectionSpace
//        var trust: SecTrust = protectionSpace.serverTrust!
//
//        // load the root CA bundled with the app
//        let certPath: String? = Bundle.main.path(forResource: "acmobile", ofType: "der")
//        if (certPath == nil) {
//            print("Certificate does not exist!")
//            return false
//        }
//
//        let certData: NSData = NSData(contentsOfFile: certPath!)!
//        let cert: SecCertificate? = SecCertificateCreateWithData(kCFAllocatorDefault, certData)
//
//        if (cert == nil) {
//            print("Certificate data could not be loaded. DER format?")
//            return false
//        }
//
//        // create a policy that ignores hostname
//        let domain: CFString? = nil
//        let policy: SecPolicy = SecPolicyCreateSSL(true, domain)
//
//        // takes all certificates from existing trust
//        let numCerts = SecTrustGetCertificateCount(trust)
//        var certs: [SecCertificate] = [SecCertificate]()
//        for i in 0..<numCerts {
//            // takeUnretainedValue
//            let c: SecCertificate? = SecTrustGetCertificateAtIndex(trust, i)
//            certs.append(c!)
//        }
//
//        // and adds them to the new policy
//        var newTrust: SecTrust? = nil
//        var err: OSStatus = SecTrustCreateWithCertificates(certs as CFTypeRef, policy, &newTrust)
//        if (err != noErr) {
//            print("Could not create trust")
//        }
//
//        // TakeUnretainedValue
//        trust = newTrust! // replace old trust
//
//        // set root cert
//        let rootCerts = [cert!] as CFArray
//        err = SecTrustSetAnchorCertificates(trust, rootCerts)
//
//        // evaluate the certificate and product a trustResult
//        // var trustResult: SecTrustResultType = SecTrustResultType()
//        var trustResult: SecTrustResultType = SecTrustResultType.unspecified // FIXME : Adrien, not sure...
//        SecTrustEvaluate(trust, &trustResult)
//
//        if ((trustResult == SecTrustResultType.proceed) || (trustResult == SecTrustResultType.unspecified)) {
//            // create the credential to be used
//
//            // FIXME : Adrien : not sure at all
//            // credential.memory = URLCredential(trust: trust)
//			print("Adrien - HEEEEREEEE")
//            return true
//        }
//
//        return false
//    }


    class func parsePageAnnotations(pages: [String: AnyObject],
                                    step: Int,
                                    documentId: String) -> [Annotation] {

        var parsedAnnotations = [Annotation]()

        for page in pages {

            if let jsonAnnotations = page.1 as? [[String: AnyObject]] {
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


    // </editor-fold desc="Static methods">


    // <editor-fold desc="Utils">


    func cancelAllOperations() {
        manager.session.invalidateAndCancel()
    }


    // </editor-fold desc="Utils">


    // <editor-fold desc="Get methods">


    func getApiVersion(onResponse responseCallback: ((NSNumber) -> Void)?,
                       onError errorCallback: ((NSError) -> Void)?) {

        let apiVersionUrl = "\(serverUrl.absoluteString!)/parapheur/api/getApiLevel"

        manager.request(apiVersionUrl, method: .get).validate().responseJSON {
            response in
            switch (response.result) {

                case .success:
                    guard let apiLevel = ApiLevel(json: response.value as! [String: AnyObject])
                    else {
                        errorCallback!(NSError(domain: self.serverUrl.absoluteString!, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                        return
                    }

					responseCallback!(NSNumber(value: apiLevel.level!))
                    break
				
                case .failure(let error):
					
                    errorCallback!(error as NSError)
                    break
            }
        }
    }

        manager.get("/parapheur/bureaux",
                    parameters: nil,
                    success: {
                        (task: URLSessionDataTask, responseObject: Any) in
                        let bureauList = [Bureau].from(jsonArray: responseObject as! [[String: AnyObject]])
                        onResponse!(bureauList! as NSArray)
                    },
                    failure: {
                        (task: URLSessionDataTask, error: Error) in
                        onError!(error as NSError)
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

        manager.get("/parapheur/dossiers",
                    parameters: paramsDict,
                    success: {
                        (task: URLSessionDataTask, responseObject: Any) in
						let dossierList = [Dossier].from(jsonArray: responseObject as! [[String: AnyObject]])
                        onResponse!(dossierList! as NSArray)
                    },
                    failure: {
                        (task: URLSessionDataTask, error: Error) in
                        onError!(error as NSError)
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

        manager.get("/parapheur/dossiers/\(dossier)",
                    parameters: paramsDict,
                    success: {
                         (task: URLSessionDataTask, responseObject: Any) in

                         guard let responseDossier = Dossier(json: responseObject as! [String: AnyObject])
                         else {
                             onError!(NSError(domain: self.manager.baseURL!.absoluteString, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                             return
                         }

                        onResponse!(responseDossier)
                     },
                    failure: {
                         (task: URLSessionDataTask, error: Error) in
                         onError!(error as NSError)
                     })
    }

    func getCircuit(dossier: NSString,
                    onResponse: ((AnyObject) -> Void)?,
                    onError: ((NSError) -> Void)?) {

        manager.get("/parapheur/dossiers/\(dossier)/circuit",
                    parameters: nil,
                    success: {
                         (task: URLSessionDataTask, responseObject: Any) in
                         onResponse!(responseObject as AnyObject)
                     },
                    failure: {
                         (task: URLSessionDataTask, error: Error) in
                         onError!(error as NSError)
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

        manager.get("/parapheur/types",
                    parameters: nil,
                    success: {
                        (task: URLSessionDataTask, responseObject: Any) in
                        let typeList = [ParapheurType].from(jsonArray: responseObject as! [[String: AnyObject]])
                        onResponse!(typeList! as NSArray)
                    },
                    failure: {
                        (task: URLSessionDataTask, error: Error) in
                        onError!(error as NSError)
                    })
    }

    func getAnnotations(dossier: NSString,
                        onResponse: (([Annotation]) -> Void)?,
                        onError: ((NSError) -> Void)?) {

        manager.get("/parapheur/dossiers/\(dossier)/annotations",
                    parameters: nil,
                    success: {
                        (task: URLSessionDataTask, responseObject: Any) in

                        // Parse

                        var parsedAnnotations = [Annotation]()

                        if let etapes = responseObject as? [AnyObject] {
                            for etapeIndex in 0 ..< etapes.count {

                                if let documentPages = etapes[etapeIndex] as? [String:AnyObject] {

                                    for documentPage in documentPages {
                                        if let pages = documentPage.1 as? [String:AnyObject] {

                                            // Parsing API4
                                            parsedAnnotations += RestClientApiV3.parsePageAnnotations(pages: pages,
                                                                                                      step: etapeIndex,
                                                                                                      documentId: documentPage.0 as String)
                                        }
                                    }

                                    // Parsing API3
                                    parsedAnnotations += RestClientApiV3.parsePageAnnotations(pages: documentPages,
                                                                                              step: etapeIndex,
                                                                                              documentId: "*")
                                }
                            }
                        }
                        else {
                            onError!(NSError(domain: self.manager.baseURL!.absoluteString,
                                             code: self.kCFURLErrorBadServerResponse,
                                             userInfo: nil))
                            return
                        }

                        onResponse!(parsedAnnotations)
                    },
                    failure: {
                        (task: URLSessionDataTask, error: Error) in
                        onError!(error as NSError)
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

        manager.get("/parapheur/dossiers/\(dossier)/getSignInfo",
                    parameters: paramsDict,
                    success: {
                         (task: URLSessionDataTask, responseObject: Any) in
                         onResponse!(responseObject as AnyObject)
                     },
                    failure: {
                         (task: URLSessionDataTask, error: Error) in
                         onError!(error as NSError)
                     })
    }

    func sendSimpleAction(type: NSNumber,
                          url: NSString,
                          args: NSDictionary,
                          onResponse: ((AnyObject) -> Void)?,
                          onError: ((NSError) -> Void)?) {

        if (type == 1) {

            manager.post(url as String,
                         parameters: args,
                         success: {
                              (task: URLSessionDataTask, responseObject: Any) in
                              onResponse!(1 as AnyObject)
                          },
                         failure: {
                              (task: URLSessionDataTask, error: Error) in
                              onError!(error as NSError)
                         })
        }
        else if (type == 2) {

            manager.put(url as String,
                        parameters: args,
                        success: {
                             (task: URLSessionDataTask, responseObject: Any) in
                             onResponse!(1 as AnyObject)
                         },
                        failure: {
                             (task: URLSessionDataTask, error: Error) in
                             onError!(error as NSError)
                         })
        }
        else if (type == 3) {

            manager.delete(url as String,
                           parameters: args,
                           success: {
                                (task: URLSessionDataTask, responseObject: Any) in
                                onResponse!(1 as AnyObject)
                            },
                           failure: {
                                (task: URLSessionDataTask, error: Error) in
                                onError!(error as NSError)
                            })
        }
    }


    // </editor-fold desc="Get methods">
}

