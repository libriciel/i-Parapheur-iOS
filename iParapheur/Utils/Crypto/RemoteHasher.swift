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

/**
    Calling the Crypto element server-side
*/
class RemoteHasher: Hasher {

    var mSignatureAlgorithm: SignatureAlgorithm {
        return .sha256WithRsa
    }

    let mSignInfo: SignInfo
    let mPublicKeyBase64: String
    var mSignatureDateTime: Int?
    var mPayload: [String: String]
    @objc var mRestClient: RestClient


    init(signInfo: SignInfo,
         publicKeyBase64: String,
         restClient: RestClient) {

        mSignInfo = signInfo
        mPublicKeyBase64 = publicKeyBase64
        mRestClient = restClient
        mPayload = [:]
    }


    // <editor-fold desc="Hasher">


    func generateHashToSign(onResponse responseCallback: ((DataToSign) -> Void)?,
                            onError errorCallback: ((Error) -> Void)?) {

        mRestClient.getDataToSign(hashBase64List: mSignInfo.hashesToSign,
                                  publicKeyBase64: mPublicKeyBase64,
                                  signatureFormat: mSignInfo.format,
                                  onResponse: {
                                      (response: DataToSign) in

                                      print("Adrien - signInfoB64   : \(self.mSignInfo.hashesToSign)")
                                      print("Adrien - PublicKey     : \(self.mPublicKeyBase64)")
                                      print("Adrien - dataToSign    : \(response.dataToSignBase64List)")
                                      print("Adrien - payload       : \(response.payload)")

                                      self.mPayload = response.payload
                                      responseCallback!(response)
                                  },
                                  onError: {
                                      (error: Error) in
                                  })
    }


    func buildDataToReturn(signatureList: [Data],
                           onResponse responseCallback: (([Data]) -> Void)?,
                           onError errorCallback: ((Error) -> Void)?) {

        var signatureBase64EncodedList: [String] = []
        for signature in signatureList {
            signatureBase64EncodedList.append(signature.base64EncodedString())
        }

        mRestClient.getFinalSignature(hashBase64List: mSignInfo.hashesToSign,
                                      signatureBase64List: signatureBase64EncodedList,
                                      publicKeyBase64: mPublicKeyBase64,
                                      signatureFormat: mSignInfo.format,
                                      signatureDateTime: mSignatureDateTime!,
                                      payload: mPayload,
                                      onResponse: {
                                          (response: [Data]) in

                                          print("Adrien - finalSignat : \(response))")
                                          responseCallback!(response)
                                      },
                                      onError: {
                                          (error: Error) in
                                      })
    }

    // </editor-fold desc="Hasher">

}
