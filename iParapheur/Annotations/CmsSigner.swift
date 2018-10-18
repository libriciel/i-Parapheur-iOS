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
    Yes, this class seems kind of useless, it's the easiest signature.
    But this wrapper eases the code factorization with other signature methods.
*/
@objc class CmsSigner: Signer {


    let mSignInfo: SignInfo
    let mPrivateKey: Certificate
    @objc var restClient: RestClient?


    @objc init(signInfo: SignInfo,
               privateKey: Certificate) {

        mSignInfo = signInfo
        mPrivateKey = privateKey
    }


    // <editor-fold desc="Signer">


    override func generateHashToSign(onResponse responseCallback: ((Data) -> Void)?,
                                     onError errorCallback: ((Error) -> Void)?) {

        let hashHex = mSignInfo.hashesToSign[0]

        let hash = CryptoUtils.data(hex: hashHex)
        let publicKeyBase64 = mPrivateKey.publicKey?.base64EncodedString() ?? ""

        restClient!.getDataToSign(hashBase64: hash.base64EncodedString(),
                                  publicKeyBase64: publicKeyBase64,
                                  onResponse: {
                                      (response: Data) in

                                      print("Adrien - signInfoB64 : \(hash.base64EncodedString())")
                                      print("Adrien - PublicKey   : \(publicKeyBase64)")
                                      print("Adrien - dataToSign  : \(response.base64EncodedString())")

                                      responseCallback!(response)
                                  },
                                  onError: {
                                      (error: Error) in
                                  })
    }


    override func buildDataToReturn(signature: Data,
                                    onResponse responseCallback: ((Data) -> Void)?,
                                    onError errorCallback: ((Error) -> Void)?) {

        let hashHex = mSignInfo.hashesToSign[0]
        let hash = CryptoUtils.data(hex: hashHex)
        let publicKeyBase64 = mPrivateKey.publicKey?.base64EncodedString() ?? ""

        restClient!.getFinalSignature(hashBase64: hash.base64EncodedString(),
                                      signatureBase64: signature.base64EncodedString(),
                                      publicKeyBase64: publicKeyBase64,
                                      onResponse: {
                                          (response: Data) in

                                          print("Adrien - finalSignat : \(response.base64EncodedString())")
                                          responseCallback!(response)
                                      },
                                      onError: {
                                          (error: Error) in
                                      })
    }

    // </editor-fold desc="Signer">

}
