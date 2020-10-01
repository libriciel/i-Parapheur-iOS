/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation
import Alamofire
import os


class RestClient: NSObject {

    var manager: Alamofire.Session
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
        configuration.httpAdditionalHeaders = HTTPHeaders.default.dictionary
        configuration.httpAdditionalHeaders!["Authorization"] = "Basic \(loginHash)"

        manager = Alamofire.Session(configuration: configuration)
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

        if match != nil {
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


    @objc func getApiVersion(onResponse responseCallback: ((NSNumber) -> Void)?,
                             onError errorCallback: ((Error) -> Void)?) {

        checkCertificate(onResponse: { (result: Bool) in

            if result {
                let apiVersionUrl = "\(self.serverUrl.absoluteString!)/parapheur/api/getApiLevel"

                self.manager.request(apiVersionUrl)
                        .validate()
                        .responseString { response in

                            switch response.result {

                                case .success:
                                    let decoder = JSONDecoder()

                                    guard let jsonData = response.value?.data(using: .utf8),
                                          let apiLevelWrapper = try? decoder.decode(ApiLevel.self, from: jsonData),
                                          let apiLevel = apiLevelWrapper.level else {
                                        errorCallback?(RuntimeError("Réponse du serveur invalide"))
                                        return
                                    }

                                    responseCallback?(NSNumber(value: apiLevel))

                                case .failure(let error):
                                    errorCallback?(error)
                            }
                        }
            }
            else {
                errorCallback?(NSError(domain: "kCFErrorDomainCFNetwork",
                                       code: 400))
            }

        })
    }


    func checkCertificate(onResponse responseCallback: ((Bool) -> Void)?) {

        let downloadFileUrl = "\(serverUrl)/certificates/g3mobile.der.txt"
        let filePathUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp.der")

        // Cleanup

        try? FileManager.default.removeItem(at: filePathUrl)
        let destination: DownloadRequest.Destination = { _, _ in
            (filePathUrl, [.createIntermediateDirectories, .removePreviousFile])
        }

        // Request

        manager.download(downloadFileUrl, to: destination)
                .validate()
                .responseData { response in
                    let isAcValid = CryptoUtils.checkCertificate(pendingDerFile: filePathUrl)
                    responseCallback?(isAcValid)
                }
    }


    func getSignInfo(publicKeyBase64: String,
                     folder: Dossier,
                     bureau: NSString,
                     onResponse responseCallback: ((SignInfo) -> Void)?,
                     onError errorCallback: ((Error) -> Void)?) {

        let getSignInfoUrl = "\(serverUrl.absoluteString!)/parapheur/signature/\(bureau)/\(folder.identifier)"

        // Parameters

        let bodyJson: [String: Any] = [
            "certificate": publicKeyBase64,
            "index": 0
        ]

        // TODO : When the app will be iOS13+, use the JSONSerialization's .withoutEscapingSlashes options.
        // instead of this ugly replacingOccurrences
        guard let poorlyEscapedBodyData = try? JSONSerialization.data(withJSONObject: bodyJson) else { return }
        let poorlyEscapedBodyString = String(data: poorlyEscapedBodyData, encoding: .utf8)!
        let properBodyString = poorlyEscapedBodyString.replacingOccurrences(of: "\\/", with: "/")
        let bodyData = properBodyString.data(using: .utf8)!

        os_log("getSignInfo url:%@", type: .debug, getSignInfoUrl)
        os_log("getSignInfo body:%@", type: .debug, String(data: bodyData, encoding: .utf8)!)

        // Request

        var request = URLRequest(url: URL(string: getSignInfoUrl)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        manager.request(request)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success(let value):

                            os_log("getSignInfo OK value:%@", type: .debug, value)
                            let jsonDecoder = JSONDecoder()

                            guard let getSignInfoJsonData = value.data(using: .utf8),
                                  let signInfoWrapper = try? jsonDecoder.decode([String: SignInfo].self, from: getSignInfoJsonData),
                                  let data = signInfoWrapper["signatureInformations"] else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(data)

                        case .failure(let error):
                            os_log("getSignInfo fail ! %d %@", type: .error, error.responseCode!, error.errorDescription!)
                            errorCallback?(error)
                    }
                }
    }


    /**
      Every i-Parapheur < 4.7
     */
    @objc func getSignInfoLegacy(folder: Dossier,
                                 bureau: NSString,
                                 onResponse responseCallback: ((SignInfoLegacy) -> Void)?,
                                 onError errorCallback: ((NSError) -> Void)?) {

        let getSignInfoUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder.identifier)/getSignInfo"

        // Parameters

        let parameters: Parameters = ["bureauCourant": bureau]

        // Request

        manager.request(getSignInfoUrl, parameters: parameters)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success(let value):
                            let jsonDecoder = JSONDecoder()

                            guard let getSignInfoJsonData = value.data(using: .utf8),
                                  let signInfoWrapper = try? jsonDecoder.decode([String: SignInfoLegacy].self, from: getSignInfoJsonData),
                                  let data = signInfoWrapper["signatureInformations"] else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur") as NSError)
                                return
                            }

                            responseCallback?(data)

                        case .failure(let error):
                            os_log("getSignInfo fail ! %d", type: .error, error.responseCode!)
                            errorCallback?(error as NSError)
                    }
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
        manager.request(getDataToSignUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .validate()
                .responseString { response in

                    os_log("getDataToSign response...", type: .debug)
                    switch response.result {

                        case .success:
                            let jsonDecoder = JSONDecoder()
                            guard let responseJsonData = response.value?.data(using: .utf8),
                                  let dataToSign = try? jsonDecoder.decode(DataToSign.self, from: responseJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            os_log("getDataToSign response : %@", type: .debug, dataToSign)
                            responseCallback?(dataToSign)

                        case .failure(let error):
                            os_log("getDataToSign error : %@", type: .error, error.localizedDescription)
                            errorCallback?(error)
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
        manager.request(getFinalSignatureUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:

                            let jsonDecoder = JSONDecoder()
                            guard let responseJsonData = response.value?.data(using: .utf8),
                                  let finalSignature = try? jsonDecoder.decode(FinalSignature.self,
                                                                               from: responseJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(StringsUtils.toDataList(base64StringList: finalSignature.signatureResultBase64List))

                        case .failure(let error):
                            errorCallback?(error)
                    }
                }
    }


    func getDesks(onResponse responseCallback: (([Bureau]) -> Void)?,
                  onError errorCallback: ((Error) -> Void)?) {

        let getBureauxUrl = "\(serverUrl.absoluteString!)/parapheur/bureaux"

        manager.request(getBureauxUrl)
                .validate()
                .responseString { response in
                    switch response.result {

                        case .success:

                            let jsonDecoder = JSONDecoder()
                            guard let getBureauxJsonData = response.value?.data(using: .utf8),
                                  let bureaux = try? jsonDecoder.decode([Bureau].self,
                                                                        from: getBureauxJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(bureaux)

                        case .failure(let error):
                            errorCallback?(error as NSError)
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

        if filterJson != nil {
            parameters["filter"] = filterJson
        }

        // Request

        manager.request(getDossiersUrl, parameters: parameters)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:

                            // Prepare

                            let jsonDecoder = JSONDecoder()
                            guard let responseJsonData = response.value?.data(using: .utf8),
                                  let dossierList = try? jsonDecoder.decode([Dossier].self,
                                                                            from: responseJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            // Retrieve delegated

                            self.getDelegateFolders(bureau: bureau,
                                                    page: 0, size: 100,
                                                    filterJson: nil,
                                                    onResponse: { (delegueList: [Dossier]) in

                                                        for dossierDelegue in delegueList {
                                                            dossierDelegue.isDelegue = true
                                                        }

                                                        responseCallback?((dossierList + delegueList))
                                                    },
                                                    onError: { (error: Error) in
                                                        errorCallback?(error)
                                                    })

                        case .failure(let error):
                            errorCallback?(error as NSError)
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

        if filterJson != nil {
            parameters["filter"] = filterJson
        }

        // Request

        manager.request(getDossiersUrl, parameters: parameters)
                .validate()
                .responseString { response in
                    switch response.result {

                        case .success:

                            let jsonDecoder = JSONDecoder()
                            guard let responseJsonData = response.value?.data(using: .utf8),
                                  let dossierList = try? jsonDecoder.decode([Dossier].self,
                                                                            from: responseJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(dossierList)

                        case .failure(let error):
                            errorCallback?(error)
                    }
                }
    }


    func getFolder(folder: String,
                   desk: String,
                   onResponse responseCallback: ((Dossier) -> Void)?,
                   onError errorCallback: ((Error) -> Void)?) {

        let getDossierUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder)"

        // Parameters

        let parameters: Parameters = ["bureauCourant": desk]

        // Request

        manager.request(getDossierUrl, parameters: parameters)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:

                            let jsonDecoder = JSONDecoder()
                            guard let responseJsonData = response.value?.data(using: .utf8),
                                  let dossier = try? jsonDecoder.decode(Dossier.self, from: responseJsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(dossier)

                        case .failure(let error):
                            errorCallback?(error as NSError)
                    }
                }
    }


    func getWorkflow(folder: String,
                     onResponse responseCallback: ((Circuit) -> Void)?,
                     onError errorCallback: ((Error) -> Void)?) {

        let getCircuitUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder)/circuit"

        // Request

        manager.request(getCircuitUrl)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:
                            let jsonDecoder = JSONDecoder()
                            jsonDecoder.dateDecodingStrategy = .millisecondsSince1970

                            guard let getCircuitJsonData = response.value?.data(using: .utf8),
                                  let circuitWrapper = try? jsonDecoder.decode([String: Circuit].self, from: getCircuitJsonData),
                                  let data = circuitWrapper["circuit"] else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(data)

                        case .failure(let error):
                            errorCallback?(error as NSError)
                    }
                }
    }


    @objc func getTypology(bureauId: NSString,
                           onResponse responseCallback: ((NSArray) -> Void)?,
                           onError errorCallback: ((NSError) -> Void)?) {

        let getTypologyUrl = "\(serverUrl.absoluteString!)/parapheur/types"

        // Request

        manager.request(getTypologyUrl)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:

                            let decoder = JSONDecoder()
                            guard let jsonData = response.value?.data(using: .utf8),
                                  let typeList = try? decoder.decode([ParapheurType].self,
                                                                     from: jsonData) else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur") as NSError)
                                return
                            }

                            responseCallback?(typeList as NSArray)

                        case .failure(let error):
                            errorCallback?(error as NSError)
                    }
                }
    }


    func getAnnotations(folder: String,
                        onResponse responseCallback: (([Annotation]) -> Void)?,
                        onError errorCallback: ((Error) -> Void)?) {

        let getTypologyUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder)/annotations"

        // Request

        manager.request(getTypologyUrl)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:
                            guard let responseValue = response.value else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }
                            let parsedAnnotations = AnnotationsUtils.parse(string: responseValue)
                            responseCallback?(parsedAnnotations)

                        case .failure(let error):
                            errorCallback?(error as NSError)
                    }
                }
    }


    func signDossier(dossierId: String,
                     bureauId: String,
                     publicAnnotation: String?,
                     privateAnnotation: String?,
                     signature: String,
                     responseCallback: ((NSNumber) -> Void)?,
                     errorCallback: ((Error) -> Void)?) {

        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation
        argumentDictionary["signature"] = signature

        // Send request

        self.sendSimpleAction(type: 1,
                              url: "/parapheur/dossiers/\(dossierId)/signature",
                              args: argumentDictionary,
                              onResponse: { id in
                                  responseCallback?(1)
                              },
                              onError: { error in
                                  errorCallback?(error)
                              })
    }


    func visa(folder: Dossier,
              bureauId: String,
              publicAnnotation: String?,
              privateAnnotation: String?,
              responseCallback: ((NSNumber) -> Void)?,
              errorCallback: ((NSError) -> Void)?) {

        let visaUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder.identifier)/visa"

        // Create arguments dictionary

        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation

        // Send request

        manager.request(visaUrl,
                        method: .post,
                        parameters: argumentDictionary,
                        encoding: JSONEncoding.default)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:
                            responseCallback?(NSNumber(value: 1))

                        case .failure(let error):
                            errorCallback?(error as NSError)
                            print(error.localizedDescription)
                    }
                }
    }


    func reject(folder: Dossier,
                bureauId: String,
                publicAnnotation: String?,
                privateAnnotation: String?,
                responseCallback: ((NSNumber) -> Void)?,
                errorCallback: ((NSError) -> Void)?) {

        let rejectUrl = "\(serverUrl.absoluteString!)/parapheur/dossiers/\(folder.identifier)/rejet"

        // Create arguments dictionary

        var argumentDictionary: [String: String] = [:]
        argumentDictionary["bureauCourant"] = bureauId
        argumentDictionary["annotPriv"] = privateAnnotation
        argumentDictionary["annotPub"] = publicAnnotation

        // Send request

        manager.request(rejectUrl,
                        method: .post,
                        parameters: argumentDictionary,
                        encoding: JSONEncoding.default)
                .validate()
                .responseString { response in

                    switch response.result {

                        case .success:
                            responseCallback?(NSNumber(value: 1))

                        case .failure(let error):
                            errorCallback?(error as NSError)
                            print(error.localizedDescription)
                    }
                }
    }


    func switchToPaperSignature(folder: Dossier,
                                desk: Bureau,
                                responseCallback: (() -> Void)?,
                                errorCallback: ((NSError) -> Void)?) {

        // Creating arguments dictionary

        var argumentDictionary = Parameters()
        argumentDictionary["bureauCourant"] = desk.identifier

        // Send request

        sendSimpleAction(type: 1,
                         url: String(format: "/parapheur/dossiers/%@/signPapier", folder.identifier),
                         args: argumentDictionary,
                         onResponse: { result in
                             responseCallback?()
                         },
                         onError: { (error: NSError) in
                             errorCallback?(error)
                         })
    }


    // <editor-fold desc="Annotations"> MARK: - Annotations


    func createAnnotation(_ annotation: Annotation,
                          folderId: String,
                          documentId: String,
                          responseCallback: ((String) -> Void)?,
                          errorCallback: ((Error) -> Void)?) {

        // Check arguments

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        guard let annotationData = try? jsonEncoder.encode(annotation) else {
            errorCallback?(RuntimeError("Impossible de créer l'annotation"))
            return
        }

        // Send request. Using directly JSON in the body.
        // Casting/passing it through a Parameter object doesn't work well.

        let annotationUrlSuffix = RestClient.getAnnotationsUrl(folderId: folderId, documentId: documentId)
        let annotationUrl = "\(serverUrl.absoluteString!)\(annotationUrlSuffix)"

        var request = URLRequest(url: URL(string: annotationUrl)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = annotationData

        manager.request(request)
                .responseJSON { response in

                    switch response.result {

                        case .success:

                            guard let jsonResult = response.value as? [String: String],
                                  let idString = jsonResult["id"] else {
                                errorCallback?(RuntimeError("Impossible de lire la réponse du serveur"))
                                return
                            }

                            responseCallback?(idString)

                        case .failure(let error):

                            errorCallback?(error)
                            print(error.localizedDescription)
                    }
                }
    }


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

        // Send request. Using directly JSON in the body.
        // Casting/passing it through a Parameter object doesn't work well.

        let annotationUrlSuffix = String(format: "%@/%@", RestClient.getAnnotationsUrl(folderId: folderId, documentId: documentId), annotation.identifier)
        let annotationUrl = "\(serverUrl.absoluteString!)\(annotationUrlSuffix)"

        var request = URLRequest(url: URL(string: annotationUrl)!)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = annotationData

        manager.request(request)
                .responseString { (response) in

                    switch response.result {

                        case .success:
                            responseCallback?()

                        case .failure(let error):
                            errorCallback?(error)
                            print(error.localizedDescription)
                    }
                }
    }


    func deleteAnnotation(annotationId: String,
                          folderId: String,
                          documentId: String,
                          onResponse responseCallback: (() -> Void)?,
                          onError errorCallback: ((Error) -> Void)?) {

        let annotationUrlSuffix = String(format: "%@/%@", RestClient.getAnnotationsUrl(folderId: folderId, documentId: documentId), annotationId)

        sendSimpleAction(type: 3,
                         url: annotationUrlSuffix,
                         args: nil,
                         onResponse: { response in
                             responseCallback?()
                         },
                         onError: { (error: NSError) in
                             errorCallback?(error as Error)
                         })
    }


    // </editor-fold desc="Annotations">


    @objc func sendSimpleAction(type: NSNumber,
                                url: String,
                                args: Parameters?,
                                onResponse responseCallback: ((NSNumber) -> Void)?,
                                onError errorCallback: ((NSError) -> Void)?) {

        let annotationUrl = "\(serverUrl.absoluteString!)\(url)"

        // Request

        switch type {

            case 1:
                manager.request(annotationUrl,
                                method: .post,
                                parameters: args,
                                encoding: JSONEncoding.default)
                        .validate()
                        .responseString { response in

                            switch response.result {

                                case .success:
                                    responseCallback?(NSNumber(value: 1))

                                case .failure(let error):
                                    errorCallback?(error as NSError)
                                    print(error.localizedDescription)
                            }
                        }

            case 2:
                manager.request(annotationUrl,
                                method: .put,
                                parameters: args,
                                encoding: JSONEncoding.default)
                        .validate()
                        .responseString { response in

                            switch response.result {

                                case .success:
                                    responseCallback?(1)

                                case .failure(let error):
                                    errorCallback?(error as NSError)
                                    print(error.localizedDescription)
                            }
                        }

            case 3:
                manager.request(annotationUrl,
                                method: .delete,
                                parameters: args)
                        .validate()
                        .responseString { response in

                            switch response.result {

                                case .success:
                                    responseCallback?(1)

                                case .failure(let error):
                                    errorCallback?(error as NSError)
                            }
                        }

            default:
                os_log("Wrong argument here", type: .error)
        }
    }


    func downloadFile(document: Document,
                      path filePath: URL,
                      onResponse responseCallback: ((String) -> Void)?,
                      onError errorCallback: ((Error) -> Void)?) {

        let pdfSuffix = document.isPdfVisual ? ";ph:visuel-pdf" : ""
        let downloadFileUrl = "\(serverUrl)/api/node/workspace/SpacesStore/\(document.identifier)/content\(pdfSuffix)"
        os_log("Document downloadUrl:%@", downloadFileUrl)

        let destination: DownloadRequest.Destination = { _, _ in
            (filePath as URL, [.createIntermediateDirectories, .removePreviousFile])
        }

        // Cancel previous download

        //	[_swiftManager.manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        //		for (NSURLSessionTask *task in downloadTasks)
        //			[task cancel];
        //	}];

        // Request

        manager.download(downloadFileUrl, to: destination)
                .validate()
                .response { response in
                    switch response.result {

                        case .success(let value):
                            responseCallback?(value!.path)

                        case .failure(let error):
                            errorCallback?(error)
                    }
                }
    }

}

