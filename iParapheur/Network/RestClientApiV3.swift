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
import Foundation
import Alamofire


@objc class RestClientApiV3: NSObject {

    let kCFURLErrorBadServerResponse = -1011
    var manager: Alamofire.SessionManager
    @objc var serverUrl: NSURL


    // <editor-fold desc="Constructor">


    @objc init(baseUrl: NSString,
               login: NSString,
               password: NSString) {

        // Process strings

        serverUrl = NSURL(string: String(RestClientApiV3.cleanupServerName(url: baseUrl)))!

        // Login

        let credentialData = "\(login):\(password)".data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        let loginHash = credentialData.base64EncodedString()

        // Create custom manager

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders!["Authorization"] = "Basic \(loginHash)"

        manager = Alamofire.SessionManager(configuration: configuration)
    }


    // </editor-fold desc="Constructor">


    // <editor-fold desc="Static methods">


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
                                                            range: NSMakeRange(0, urlFixed.count))

        if (match != nil) {
            let swiftRange = Range(match!.range(at: 1), in: urlFixed)
            urlFixed = String(urlFixed[swiftRange!])
        }

        return NSString(string: "https://m.\(urlFixed)")
    }


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


    @objc func cancelAllOperations() {
        manager.session.invalidateAndCancel()
    }


    // </editor-fold desc="Utils">


    // <editor-fold desc="Get methods">


    @objc func getApiVersion(onResponse responseCallback: ((NSNumber) -> Void)?,
                             onError errorCallback: ((NSError) -> Void)?) {

        checkCertificate(onResponse: {
            (result: Bool) in

            if (result) {
                let apiVersionUrl = "\(self.serverUrl.absoluteString!)/parapheur/api/getApiLevel"

                self.manager.request(apiVersionUrl).validate().responseJSON {
                    response in
                    switch (response.result) {

                        case .success:
                            guard let apiLevel = ApiLevel(json: response.value as! [String: AnyObject]) else {
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
            else {
                errorCallback!(NSError(domain: "kCFErrorDomainCFNetwork",
                                       code: 400))
            }

        })
    }


    func checkCertificate(onResponse responseCallback: ((Bool) -> Void)?) {

        let downloadFileUrl = "\(serverUrl)/certificates/g3mobile.der.txt"
        let filePathUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp.pem")

        // Cleanup

        try? FileManager.default.removeItem(at: filePathUrl)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (filePathUrl, [.createIntermediateDirectories, .removePreviousFile])
        }

        // Request

        manager.download(downloadFileUrl, to: destination).validate().responseData {
            response in

            let isAcValid = CryptoUtils.checkCertificate(pendingDerFile: filePathUrl)
            responseCallback!(isAcValid)
        }
    }


    @objc func getBureaux(onResponse responseCallback: ((NSArray) -> Void)?,
                          onError errorCallback: ((NSError) -> Void)?) {

        let getBureauxUrl = "\(serverUrl.absoluteString!)/parapheur/bureaux"

        manager.request(getBureauxUrl).validate().responseJSON {
            response in
            switch (response.result) {

                case .success:
                    let bureauList = [Bureau].from(jsonArray: response.value as! [[String: AnyObject]])
                    responseCallback!(bureauList! as NSArray)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc  func getDossiers(bureau: NSString,
                            page: NSNumber,
                            size: NSNumber,
                            filterJson: NSString?,
                            onResponse responseCallback: ((NSArray) -> Void)?,
                            onError errorCallback: ((NSError) -> Void)?) {

        let getDossiersUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers"

        // Parameters

        var parameters: Parameters = [
            "asc": true,
            "bureau": bureau,
            "page": page,
            "pageSize": size,
            "pendingFile": 0,
			"skipped": Double(truncating: page) * (Double(truncating: size) - 1),
            "sort": "cm:create"
        ]

        if (filterJson != nil) {
            parameters["filter"] = filterJson
        }

        // Request

        manager.request(getDossiersUrl, parameters: parameters).validate().responseJSON {
            response in
            switch (response.result) {

                case .success:
                    let dossierList = [Dossier].from(jsonArray: response.value as! [[String: AnyObject]])
                    responseCallback!(dossierList! as NSArray)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getDossier(dossier: NSString,
                          bureau: NSString,
                          onResponse responseCallback: ((Dossier) -> Void)?,
                          onError errorCallback: ((NSError) -> Void)?) {

        let getDossierUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)"

        // Parameters

        let parameters: Parameters = ["bureauCourant": bureau]

        // Request

        manager.request(getDossierUrl, parameters: parameters).validate().responseJSON {
            response in
            switch (response.result) {

                case .success:
                    guard let responseDossier = Dossier(json: response.value as! [String: AnyObject]) else {
                        errorCallback!(NSError(domain: self.serverUrl.absoluteString!, code: self.kCFURLErrorBadServerResponse, userInfo: nil))
                        return
                    }
                    responseCallback!(responseDossier)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getCircuit(dossier: NSString,
                          onResponse responseCallback: ((AnyObject) -> Void)?,
                          onError errorCallback: ((NSError) -> Void)?) {

        let getCircuitUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)/circuit"

        // Request

        manager.request(getCircuitUrl).validate().responseJSON {
            response in
            switch (response.result) {

                case .success:
                    responseCallback!(response.value as AnyObject)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getTypology(bureauId: NSString,
                           onResponse responseCallback: ((NSArray) -> Void)?,
                           onError errorCallback: ((NSError) -> Void)?) {

        let getTypologyUrl = "\(serverUrl.absoluteString!)/parapheur/types"

        // Request

        manager.request(getTypologyUrl).validate().responseJSON {
            response in

            switch (response.result) {

                case .success:
                    let typeList = [ParapheurType].from(jsonArray: response.value as! [[String: AnyObject]])
                    responseCallback!(typeList! as NSArray)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getAnnotations(dossier: NSString,
                              onResponse responseCallback: (([Annotation]) -> Void)?,
                              onError errorCallback: ((NSError) -> Void)?) {

        let getTypologyUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)/annotations"

        // Request

        manager.request(getTypologyUrl).validate().responseJSON {
            response in

            switch (response.result) {

                case .success:
                    var parsedAnnotations = [Annotation]()

                    if let etapes = response.value as? [AnyObject] {
                        for etapeIndex in 0..<etapes.count {

                            if let documentPages = etapes[etapeIndex] as? [String: AnyObject] {

                                for documentPage in documentPages {
                                    if let pages = documentPage.1 as? [String: AnyObject] {

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
                        errorCallback!(NSError(domain: self.serverUrl.absoluteString!,
                                               code: self.kCFURLErrorBadServerResponse,
                                               userInfo: nil))
                        return
                    }

                    responseCallback!(parsedAnnotations)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getSignInfo(dossier: NSString,
                           bureau: NSString,
                           onResponse responseCallback: ((SignInfo) -> Void)?,
                           onError errorCallback: ((NSError) -> Void)?) {

        let getSignInfoUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)/getSignInfo"

        // Parameters

        let parameters: Parameters = ["bureauCourant": bureau]

        // Request

        manager.request(getSignInfoUrl, parameters: parameters).validate().responseString {
            response in

            switch (response.result) {

                case .success:
                    do {
                        let getSignInfoJsonData = response.result.value!.data(using: .utf8)!
                        let jsonDecoder = JSONDecoder()
                        let signInfoDict = try? jsonDecoder.decode([String: SignInfo].self,
                                                                   from: getSignInfoJsonData)

                        let signInfo = signInfoDict!["signatureInformations"]
                        responseCallback!(signInfo!)
                    }
                    catch let error {
                        errorCallback!(error as NSError)
                    }
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func sendSimpleAction(type: NSNumber,
                                url: NSString,
                                args: NSDictionary,
                                onResponse responseCallback: ((NSNumber) -> Void)?,
                                onError errorCallback: ((NSError) -> Void)?) {

        // Conversions ObjC -> Swift

        let annotationUrl = "\(serverUrl.absoluteString!)\(url)"
        var parameters: Parameters = [:]
        for arg in args {
            parameters[arg.key as! String] = arg.value
        }

        // Request

        if (type == 1) {
            manager.request(annotationUrl,
                            method: .post,
                            parameters: parameters,
                            encoding: JSONEncoding.default).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback!(NSNumber(value: 1))
                        break

                    case .failure(let error):
                        errorCallback!(error as NSError)
                        print(error.localizedDescription)
                        break
                }
            }
        }
        else if (type == 2) {

            manager.request(annotationUrl,
                            method: .put,
                            parameters: parameters,
                            encoding: JSONEncoding.default).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback!(NSNumber(value: 1))
                        break

                    case .failure(let error):
                        errorCallback!(error as NSError)
                        print(error.localizedDescription)
                        break
                }
            }
        }
        else if (type == 3) {

            manager.request(annotationUrl,
                            method: .delete,
                            parameters: parameters).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback!(NSNumber(value: 1))
                        break

                    case .failure(let error):
                        errorCallback!(error as NSError)
                        break
                }
            }
        }
    }


    // </editor-fold desc="Get methods">


    @objc func downloadFile(document: NSString,
                            isPdf: Bool,
                            atPath filePath: NSURL,
                            onResponse responseCallback: ((NSString) -> Void)?,
                            onError errorCallback: ((NSError) -> Void)?) {

        let pdfSuffix = isPdf ? ";ph:visuel-pdf" : ""
        let downloadFileUrl = "\(serverUrl)/api/node/workspace/SpacesStore/\(document)/content\(pdfSuffix)"
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (filePath as URL, [.createIntermediateDirectories, .removePreviousFile])
        }

        // Cancel previous download

        //	[_swiftManager.manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        //		for (NSURLSessionTask *task in downloadTasks)
        //			[task cancel];
        //	}];

        // Request

        manager.download(downloadFileUrl, to: destination).validate().response {
            response in

            if (response.error == nil) {
                responseCallback!(response.destinationURL!.path as NSString)
            }
            //	else if (response.error.code != -999) { // CFNetworkErrors.kCFURLErrorCancelled
            //		errorCallback!(response.error)
            //	}
            else {
                errorCallback!(response.error! as NSError)
            }
        }
    }

}

