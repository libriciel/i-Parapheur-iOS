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
import os

/**
    Calling the Crypto element server-side
*/
class RemoteHasher {


    static public let payloakKeyPesSignatureDateTime = "signaturedate"
    static public let payloakKeyPesClaimedRole = "pesclaimedrole"
    static public let payloakKeyPesPostalCode = "pespostalcode"
    static public let payloakKeyPesCountryName = "pescountryname"
    static public let payloakKeyPesCity = "pescity"


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


    func generateHashToSign(onResponse responseCallback: ((DataToSign) -> Void)?,
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
                                 onResponse:
                                 { (response: DataToSign) in
                                     os_log("mRestClient#getDataToSign hashes : %@", type: .debug, response.dataToSignBase64List)
                                     self.dataToSign = response
                                     responseCallback?(response)
                                 },
                                 onError: { (error: Error) in
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
