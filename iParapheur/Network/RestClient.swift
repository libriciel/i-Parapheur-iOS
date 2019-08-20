/*
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

import Foundation
import Alamofire
import os


class RestClient: NSObject {

    var manager: Alamofire.SessionManager
    @objc var serverUrl: NSURL


    // <editor-fold desc="Constructor">


    @objc init(baseUrl: NSString,
               login: NSString,
               password: NSString) {

        // Process strings

        serverUrl = NSURL(string: String(RestClient.cleanupServerName(url: baseUrl)))!

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
        //			- then ignore following "m-" or "m." (if exists)				(?:m[-\\.])*
        //			- then catch every char but "/"									([^\/]*)
        //			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
        let regex: NSRegularExpression = try! NSRegularExpression(pattern: "^(?:.*:\\/\\/)*(?:m[-\\.])*([^\\/]*)(?:\\/.*)*$",
                                                                  options: NSRegularExpression.Options.caseInsensitive)

        let match: NSTextCheckingResult? = regex.firstMatch(in: urlFixed,
                                                            options: NSRegularExpression.MatchingOptions.anchored,
                                                            range: NSMakeRange(0, urlFixed.count))

        if (match != nil) {
            let swiftRange = Range(match!.range(at: 1), in: urlFixed)
            urlFixed = String(urlFixed[swiftRange!])
        }

        return NSString(string: "https://m-\(urlFixed)")
    }


    class func getAnnotationsUrl(folderId: String, documentId: String) -> String {
        return String(format: "/parapheur/dossiers/%@/%@/annotations", folderId, documentId)
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

                self.manager.request(apiVersionUrl).validate().responseString {
                    response in
                    switch (response.result) {

                        case .success:
                            let decoder = JSONDecoder()
                            let jsonData = response.value?.data(using: .utf8)!
                            let apiLevel = try? decoder.decode(ApiLevel.self, from: jsonData!)
                            responseCallback!(NSNumber(value: (apiLevel?.level)!))
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
        let filePathUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp.der")

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


    func getDataToSign(remoteDocumentList: [RemoteDocument],
                       publicKeyBase64: String,
                       signatureFormat: String,
                       payload: [String: String],
                       onResponse responseCallback: ((DataToSign) -> Void)?,
                       onError errorCallback: ((Error) -> Void)?) {

        os_log("getDataToSign called", type: .debug)

        let getDataToSignUrl = "\(serverUrl.absoluteString!)/crypto/api/generateDataToSign"

        // Parameters

        // Alamofire can't stand Encodable object in its Parameters.
        // We have to either re-create the full request, with a JSON raw data body
        // Or just create a [String:String] map list in a loop, and add the 2 or 3 parameters.
        //
        // ... Yep, I chose the second.
        //
        // RemoteObject is still an Encodable object, if in any future date, AlamoFire supports it.

        var remoteDocumentMapList: [[String: String]] = []
        for remoteDocument in remoteDocumentList {
            remoteDocumentMapList.append(["id": remoteDocument.id,
                                          "digestBase64": remoteDocument.digestBase64])
        }

        let parameters: Parameters = [
            "remoteDocumentList": remoteDocumentMapList,
            "signatureFormat": signatureFormat,
            "publicKeyBase64": publicKeyBase64,
            "payload": payload
        ]

        // Request

        os_log("getDataToSign request sent with parameters %@", type: .debug, parameters)
        manager.request(getDataToSignUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseString {
            response in

            os_log("getDataToSign response...", type: .debug)
            switch (response.result) {

                case .success:

                    // Prepare

                    let responseJsonData = response.value!.data(using: .utf8)!
                    let jsonDecoder = JSONDecoder()
                    let dataToSign = try? jsonDecoder.decode(DataToSign.self,
                                                             from: responseJsonData)

                    os_log("getDataToSign response : %@", type: .debug, dataToSign!)
                    responseCallback!(dataToSign!)
                    break

                case .failure(let error):
                    os_log("getDataToSign error : %@", type: .error, error.localizedDescription)
                    errorCallback!(error)
                    break
            }
        }
    }


    func getFinalSignature(remoteDocumentList: [RemoteDocument],
                           publicKeyBase64: String,
                           signatureDateTime: Int,
                           signatureFormat: String,
                           payload: [String: String],
                           onResponse responseCallback: (([Data]) -> Void)?,
                           onError errorCallback: ((Error) -> Void)?) {

        let getFinalSignatureUrl = "\(serverUrl.absoluteString!)/crypto/api/generateSignature"

        // Parameters

        // Alamofire can't stand Encodable object in its Parameters.
        // We have to either re-create the full request, with a JSON raw data body
        // Or just create a [String:String] map list in a loop, and add the 2 or 3 parameters.
        //
        // ... Yep, I chose the second.
        //
        // RemoteObject is still an Encodable object, if in any future date, AlamoFire supports it.

        var remoteDocumentMapList: [[String: String]] = []
        for remoteDocument in remoteDocumentList {
            remoteDocumentMapList.append(["id": remoteDocument.id,
                                          "digestBase64": remoteDocument.digestBase64,
                                          "signatureBase64": remoteDocument.signatureBase64!])
        }

        let parameters: Parameters = [
            "remoteDocumentList": remoteDocumentMapList,
            "signatureFormat": signatureFormat,
            "publicKeyBase64": publicKeyBase64,
            "signatureDateTime": signatureDateTime,
            "payload": payload
        ]

        // Request

        os_log("getFinalSignature request sent with parameters %@", type: .debug, parameters)
        manager.request(getFinalSignatureUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseString {
            response in

            switch (response.result) {

                case .success:

                    // Prepare

                    let responseJsonData = response.value!.data(using: .utf8)!
                    let jsonDecoder = JSONDecoder()
                    let finalSignature = try? jsonDecoder.decode(FinalSignature.self,
                                                                 from: responseJsonData)

                    responseCallback!(StringsUtils.toDataList(base64StringList: finalSignature!.signatureResultBase64List))
                    break

                case .failure(let error):
                    errorCallback!(error)

                    break
            }
        }
    }


    func getDesks(onResponse responseCallback: (([Bureau]) -> Void)?,
                  onError errorCallback: ((Error) -> Void)?) {

        let getBureauxUrl = "\(serverUrl.absoluteString!)/parapheur/bureaux"

        manager.request(getBureauxUrl).validate().responseString {
            response in
            switch (response.result) {

                case .success:

                    // Prepare

                    let getBureauxJsonData = response.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    let bureaux = try? jsonDecoder.decode([Bureau].self,
                                                          from: getBureauxJsonData)

                    // Parsing and callback

                    if (bureaux != nil) {
                        responseCallback!(bureaux!)
                    }
                    else {
                        errorCallback!(NSError(domain: "Invalid response",
                                               code: 999))
                    }

                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    func getDossiers(bureau: String,
                     page: Int,
                     size: Int,
                     filterJson: String?,
                     onResponse responseCallback: (([Dossier]) -> Void)?,
                     onError errorCallback: ((Error) -> Void)?) {

        let getDossiersUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers"

        // Parameters

        var parameters: Parameters = [
            "asc": true,
            "bureau": bureau,
            "page": page,
            "pageSize": size,
            "pendingFile": 0,
            "skipped": page * size,
            "sort": "cm:create"
        ]

        if (filterJson != nil) {
            parameters["filter"] = filterJson
        }

        // Request

        manager.request(getDossiersUrl, parameters: parameters).validate().responseString {
            response in
            switch (response.result) {

                case .success:

                    // Prepare

                    let responseJsonData = response.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    let dossierList = try? jsonDecoder.decode([Dossier].self,
                                                              from: responseJsonData)

                    // Retrieve delegated

                    self.getDelegateFolders(bureau: bureau,
                                            page: 0, size: 100,
                                            filterJson: nil,
                                            onResponse: {
                                                (delegueList: [Dossier]) in

                                                for dossierDelegue in delegueList {
                                                    dossierDelegue.isDelegue = true;
                                                }

                                                responseCallback!((dossierList! + delegueList))
                                            },
                                            onError: {
                                                (error: Error) in
                                                errorCallback!(error)
                                            })
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    func getDelegateFolders(bureau: String,
                            page: Int,
                            size: Int,
                            filterJson: String?,
                            onResponse responseCallback: (([Dossier]) -> Void)?,
                            onError errorCallback: ((Error) -> Void)?) {

        let getDossiersUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers"

        // Parameters

        var parameters: Parameters = [
            "asc": true,
            "bureau": bureau,
            "page": page,
            "pageSize": size,
            "corbeilleName": "dossiers-delegues",
            "pendingFile": 0,
            "skipped": page * size,
            "sort": "cm:create"
        ]

        if (filterJson != nil) {
            parameters["filter"] = filterJson
        }

        // Request

        manager.request(getDossiersUrl, parameters: parameters).validate().responseString {
            response in
            switch (response.result) {

                case .success:

                    let responseJsonData = response.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    let dossierList = try? jsonDecoder.decode([Dossier].self,
                                                              from: responseJsonData)

                    responseCallback!(dossierList!)
                    break

                case .failure(let error):
                    errorCallback!(error)
                    break
            }
        }
    }


    func getDossier(dossier: String,
                    bureau: String,
                    onResponse responseCallback: ((Dossier) -> Void)?,
                    onError errorCallback: ((Error) -> Void)?) {

        let getDossierUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)"

        // Parameters

        let parameters: Parameters = ["bureauCourant": bureau]

        // Request

        manager.request(getDossierUrl, parameters: parameters).validate().responseString {
            response in
            switch (response.result) {

                case .success:

                    let responseJsonData = response.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    let dossier = try? jsonDecoder.decode(Dossier.self,
                                                          from: responseJsonData)

                    responseCallback!(dossier!)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    func getCircuit(dossier: String,
                    onResponse responseCallback: ((Circuit) -> Void)?,
                    onError errorCallback: ((Error) -> Void)?) {

        let getCircuitUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)/circuit"

        // Request

        manager.request(getCircuitUrl).validate().responseString {
            response in

            switch (response.result) {

                case .success:

                    // Prepare

                    let getCircuitJsonData = response.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
                    let circuitWrapper = try? jsonDecoder.decode([String: Circuit].self,
                                                                 from: getCircuitJsonData)

                    // Parsing and callback

                    let hasSomeData = (circuitWrapper != nil) && (circuitWrapper!["circuit"] != nil)
                    if (hasSomeData) {
                        responseCallback!(circuitWrapper!["circuit"]!)
                    }
                    else {
                        errorCallback!(NSError(domain: "Invalid response",
                                               code: 999))
                    }

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

        manager.request(getTypologyUrl).validate().responseString {
            response in

            switch (response.result) {

                case .success:

                    let decoder = JSONDecoder()
                    let jsonData = response.value?.data(using: .utf8)!
                    let typeList = try? decoder.decode([ParapheurType].self,
                                                       from: jsonData!)

                    responseCallback!(typeList! as NSArray)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    func getAnnotations(dossier: String,
                        onResponse responseCallback: (([Annotation]) -> Void)?,
                        onError errorCallback: ((Error) -> Void)?) {

        let getTypologyUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier)/annotations"

        // Request

        manager.request(getTypologyUrl).validate().responseString {
            response in

            switch (response.result) {

                case .success:
                    let parsedAnnotations = AnnotationsUtils.parse(string: response.value!)
                    responseCallback!(parsedAnnotations)
                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func getSignInfo(dossier: Dossier,
                           bureau: NSString,
                           onResponse responseCallback: ((SignInfo) -> Void)?,
                           onError errorCallback: ((NSError) -> Void)?) {

        let getSignInfoUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier.identifier)/getSignInfo"

        // Parameters

        let parameters: Parameters = ["bureauCourant": bureau]

        // Request

        manager.request(getSignInfoUrl, parameters: parameters).validate().responseString {
            response in

            switch (response.result) {

                case .success:

                    // Prepare

                    let getSignInfoJsonData = response.result.value!.data(using: .utf8)!

                    let jsonDecoder = JSONDecoder()
                    let signInfoWrapper = try? jsonDecoder.decode([String: SignInfo].self,
                                                                  from: getSignInfoJsonData)

                    // Parsing and callback

                    let hasSomeData = (signInfoWrapper != nil) && (signInfoWrapper!["signatureInformations"] != nil)
                    if (hasSomeData) {
                        responseCallback!(signInfoWrapper!["signatureInformations"]!)
                    }
                    else {
                        errorCallback!(NSError(domain: "Invalid response",
                                               code: 999))
                    }

                    break

                case .failure(let error):
                    errorCallback!(error as NSError)
                    break
            }
        }
    }


    @objc func signDossier(dossierId: String,
                           bureauId: String,
                           publicAnnotation: String?,
                           privateAnnotation: String?,
                           signature: String,
                           responseCallback: ((NSNumber) -> Void)?,
                           errorCallback: ((NSError) -> Void)?) {


        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation
        argumentDictionary["signature"] = signature

        // Send request

        self.sendSimpleAction(type: 1,
                              url: "/parapheur/dossiers/\(dossierId)/signature",
                              args: argumentDictionary,
                              onResponse: {
                                  id in
                                  responseCallback!(1);
                              },
                              onError: {
                                  error in
                                  errorCallback!(error as NSError);
                              })
    }


    func visa(dossier: Dossier,
              bureauId: String,
              publicAnnotation: String?,
              privateAnnotation: String?,
              responseCallback: ((NSNumber) -> Void)?,
              errorCallback: ((NSError) -> Void)?) {

        let visaUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier.identifier)/visa"

        // Create arguments dictionary

        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation

        // Send request

        manager.request(visaUrl,
                        method: .post,
                        parameters: argumentDictionary,
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


    func reject(dossier: Dossier,
                bureauId: String,
                publicAnnotation: String?,
                privateAnnotation: String?,
                responseCallback: ((NSNumber) -> Void)?,
                errorCallback: ((NSError) -> Void)?) {

        let rejectUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(dossier.identifier)/rejet"

        // Create arguments dictionary

        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation

        // Send request

        manager.request(rejectUrl,
                        method: .post,
                        parameters: argumentDictionary,
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


    // </editor-fold desc="Get methods">


    // <editor-fold desc="Annotations"> MARK: - Annotations


    func updateAnnotation(_ annotation: Annotation,
                          folderId: String,
                          documentId: String,
                          responseCallback: (() -> Void)?,
                          errorCallback: ((Error) -> Void)?) {

        // Check arguments

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        guard let annotationData = try? jsonEncoder.encode(annotation) else {
            errorCallback?(RuntimeError("Impossible de créer l'annotation"))
            return
        }

        // Send request

        let annotationUrlSuffix = String(format: "%@/%@", RestClient.getAnnotationsUrl(folderId: folderId, documentId: documentId), annotation.identifier)
        let annotationUrl = "\(serverUrl.absoluteString!)\(annotationUrlSuffix)"

        var request = URLRequest(url: URL(string: annotationUrl)!)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = annotationData

        manager.request(request).responseString {
            (response) in

            switch (response.result) {

                case .success:
                    responseCallback?()
                    break

                case .failure(let error):
                    errorCallback?(error)
                    print(error.localizedDescription)
                    break
            }
        }
    }


    // </editor-fold desc="Annotations">


    @objc func sendSimpleAction(type: NSNumber,
                                url: String,
                                args: Parameters,
                                onResponse responseCallback: ((NSNumber) -> Void)?,
                                onError errorCallback: ((NSError) -> Void)?) {

        let annotationUrl = "\(serverUrl.absoluteString!)\(url)"

        // Request

        if (type == 1) {
            manager.request(annotationUrl,
                            method: .post,
                            parameters: args,
                            encoding: JSONEncoding.default).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback!(NSNumber(value: 1))
                        break

                    case .failure(let error):
                        errorCallback?(error as NSError)
                        print(error.localizedDescription)
                        break
                }
            }
        }
        else if (type == 2) {

            manager.request(annotationUrl,
                            method: .put,
                            parameters: args,
                            encoding: JSONEncoding.default).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback?(1)
                        break

                    case .failure(let error):
                        errorCallback?(error as NSError)
                        print(error.localizedDescription)
                        break
                }
            }
        }
        else if (type == 3) {

            manager.request(annotationUrl,
                            method: .delete,
                            parameters: args).validate().responseString {
                response in

                switch (response.result) {

                    case .success:
                        responseCallback?(1)
                        break

                    case .failure(let error):
                        errorCallback?(error as NSError)
                        break
                }
            }
        }
    }


    func downloadFile(document: Document,
                      path filePath: URL,
                      onResponse responseCallback: ((String) -> Void)?,
                      onError errorCallback: ((Error) -> Void)?) {

        let pdfSuffix = document.isPdfVisual ? ";ph:visuel-pdf" : ""
        let downloadFileUrl = "\(serverUrl)/api/node/workspace/SpacesStore/\(document.identifier)/content\(pdfSuffix)"
        os_log("Document downloadUrl:%@", downloadFileUrl)
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
                responseCallback!(response.destinationURL!.path)
            }
            //	else if (response.error.code != -999) { // CFNetworkErrors.kCFURLErrorCancelled
            //		errorCallback?(response.error)
            //	}
            else {
                errorCallback?(response.error!)
            }
        }
    }

}

