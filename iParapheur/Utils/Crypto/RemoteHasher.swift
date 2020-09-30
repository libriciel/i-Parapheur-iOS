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

/**
    Calling the Crypto element server-side
*/
class RemoteHasher {


    static public let payloadKeyPesSignatureDateTime = "signaturedate"
    static public let payloadKeyPesClaimedRole = "pesclaimedrole"
    static public let payloadKeyPesPostalCode = "pespostalcode"
    static public let payloadKeyPesCountryName = "pescountryname"
    static public let payloadKeyPesCity = "pescity"


    let signatureAlgorithm: SignatureAlgorithm
    let signInfo: SignInfo
    let publicKeyBase64: String
    var dossier: Dossier
    var payload: [String: String]
    var dataToSign: DataToSign?
    @objc var restClient: RestClient


    init(signInfo: SignInfo,
         publicKeyBase64: String,
         dossier: Dossier,
         restClient: RestClient,
         signatureAlgorithm: SignatureAlgorithm) {

        self.dossier = dossier
        self.signInfo = signInfo
        self.publicKeyBase64 = publicKeyBase64
        self.restClient = restClient
        self.signatureAlgorithm = signatureAlgorithm
        self.payload = [:]
    }


    // <editor-fold desc="Hasher">


    func generateHashToSign(deskId: String,
                            onResponse responseCallback: ((DataToSign) -> Void)?,
                            onError errorCallback: ((Error) -> Void)?) {

        os_log("RemoteHasher#generateHashToSign", type: .debug)

        var remoteDocumentList: [RemoteDocument] = []
        for i in 0..<signInfo.hashesToSign.count {

            os_log("RemoteHasher#generateHashToSign %@", type: .debug, signInfo.hashesToSign)
            let hashToSignData: Data = CryptoUtils.data(hex: signInfo.hashesToSign[i])
            let hashToSignBase64 = hashToSignData.base64EncodedString()
            let remoteDocumentId = (signInfo.pesIds.count > 0) ? signInfo.pesIds[i] : dossier.documents[i].identifier

            remoteDocumentList.append(RemoteDocument(id: remoteDocumentId,
                                                     digestBase64: hashToSignBase64,
                                                     signatureBase64: nil))
        }

        restClient.getDataToSign(remoteDocumentList: remoteDocumentList,
                                 publicKeyBase64: publicKeyBase64,
                                 signatureFormat: signInfo.format,
                                 payload: payload,
                                     os_log("mRestClient#getDataToSign hashes : %@", type: .debug, response.dataToSignBase64List)
                                 onResponse: { (response: DataToSign) in
                                     self.dataToSign = response
                                     responseCallback?(response)
                                 },
                                 onError: { [self] (error: Error) in
                                     os_log("RemoteHasher#generateHashToSign error : %@", type: .error, error.localizedDescription)
                                     errorCallback?(error)
                                 })
    }


    func buildDataToReturn(signatureList: [Data],
                           onResponse responseCallback: (([Data]) -> Void)?,
                           onError errorCallback: ((Error) -> Void)?) {

        os_log("RemoteHasher#buildDataToReturn", type: .debug)

        var remoteDocumentList: [RemoteDocument] = []
        for i in 0..<signInfo.hashesToSign.count {

            let hashToSignData: Data = CryptoUtils.data(hex: signInfo.hashesToSign[i])
            let hashToSignBase64 = hashToSignData.base64EncodedString()
            let remoteDocumentId = (signInfo.pesIds.count > 0) ? signInfo.pesIds[i] : dossier.documents[i].identifier

            remoteDocumentList.append(RemoteDocument(id: remoteDocumentId,
                                                     digestBase64: hashToSignBase64,
                                                     signatureBase64: signatureList[i].base64EncodedString()))
        }

        restClient.getFinalSignature(remoteDocumentList: remoteDocumentList,
                                     publicKeyBase64: publicKeyBase64,
                                     signatureDateTime: dataToSign!.signatureDateTime,
                                     signatureFormat: signInfo.format,
                                     payload: payload,
                                     onResponse: { (response: [Data]) in
                                         responseCallback?(response)
                                     },
                                     onError: { (error: Error) in
                                         os_log("RemoteHasher#buildDataToReturn error : %@", type: .error, error.localizedDescription)
                                         errorCallback?(error)
                                     })
    }


    // </editor-fold desc="Hasher">

}
