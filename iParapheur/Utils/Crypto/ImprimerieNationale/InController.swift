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


extension Notification.Name {

    static let imprimerieNationaleCertificateImport = Notification.Name("ImprimerieNationaleCertificateImport")
}


class InController: NSObject {


    class func getTokenData() {

        let urlString = """
                            inmiddleware://getTokenData/ {

                                "responseScheme" : "iparapheur",
                                "tokenExpectedData" : {
                                    "middleware" : "all",
                                    "token" : "all",
                                    "certificates" : "all"
                                }
                            }
                        """

        let cleanedString = StringsUtils.trim(string: urlString)
        let urlEncodedString = cleanedString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlEncodedString)!

        UIApplication.shared.open(url,
                                  completionHandler: { (result) in
                                      if result {
                                          print("Result OK")
                                      }
                                  })
    }


    @objc class func sign(hashes: [Data], certificateId: String, signatureAlgorithm: SignatureAlgorithm) {

        let mechanism = (signatureAlgorithm == .sha1WithRsa) ? "rsa" : "sha256rsa"
        var hashesJsonList: [String] = []
        for hash in hashes {

            var hexDataToSign: String
            if (signatureAlgorithm == .sha1WithRsa) {
                hexDataToSign = "\(CryptoUtils.pkcs15Asn1HexPrefix)\(CryptoUtils.hex(data: hash.sha1()))"
            }
            else {
                hexDataToSign = CryptoUtils.hex(data: hash)
            }

            hashesJsonList.append("""
                                      {
                                          "certificateId" : " \(certificateId) ",
                                          "data" : " \(hexDataToSign) "
                                      }
                                  """)
        }

        let urlString = """
                            inmiddleware://sign/ {

                                "responseScheme" : "iparapheur",
                                "mechanism" : "\(mechanism)",
                                "values" : [
                                    \(hashesJsonList.joined(separator: ","))
                                ]
                            }
                        """

        let cleanedString = StringsUtils.trim(string: urlString)
        print("Request sent :: \(cleanedString)")
        let urlEncodedString = cleanedString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlEncodedString)!

        print("Request sent :: \(url.absoluteString)")

        UIApplication.shared.open(url,
                                  completionHandler: { (result) in
                                      if result {
                                          print("Result OK")
                                      }
                                  })
    }


    @objc class func parseIntent(url: URL) -> Bool {

        if (url.scheme != "iparapheur") {
            return false
        }

        let jsonDecoder = JSONDecoder()
        let croppedUrl = String(url.path.dropFirst())

        let tokenData = try? jsonDecoder.decode(InTokenData.self, from: croppedUrl.data(using: .utf8)!)
        if (tokenData != nil) {

            for (identifier, data) in tokenData!.certificates {

                let x509 = ADLKeyStore.x509(fromPem: data.base64EncodedString())
                let x509Values = ADLKeyStore.parseX509Values(x509) as! [String: AnyObject]
                let keyUsage = String(describing: x509Values["keyUsage"])

                if (!keyUsage.contains("Non Repudiation")) {
                    tokenData!.certificates.removeValue(forKey: identifier)
                }
            }

            importCertificate(token: tokenData!)
            NotificationCenter.default.post(name: .imprimerieNationaleCertificateImport, object: nil)
            return true
        }

        let inSignedData = try? jsonDecoder.decode(InSignedData.self, from: croppedUrl.data(using: .utf8)!)
        if (inSignedData != nil) {

            // FIXME : Hardcoded (hopefully a temporary fix)
            inSignedData!.signedData.removeLast(4)
            let signedData = CryptoUtils.data(hex: inSignedData!.signedData)

            NotificationCenter.default.post(name: .signatureResult,
                                            object: nil,
                                            userInfo: [
                                                CryptoUtils.notifSignedData: [signedData],
                                                CryptoUtils.notifSignatureIndex: 0
                                            ])
            return true
        }

        return false
    }


    class func importCertificate(token: InTokenData) {

        for (externalId, publicKey) in token.certificates {

            let context = ModelsDataController.context!
            let newCertificate = NSEntityDescription.insertNewObject(forEntityName: Certificate.entityName, into: context) as! Certificate

            let x509 = ADLKeyStore.x509(fromPem: publicKey.base64EncodedString())
            let x509Values = ADLKeyStore.parseX509Values(x509) as! [String: AnyObject]

            newCertificate.sourceType = .imprimerieNationale
            newCertificate.caName = token.manufacturerId
            newCertificate.commonName = "\(token.manufacturerId) \(token.serialNumber)"
            newCertificate.serialNumber = token.serialNumber
            newCertificate.identifier = UUID().uuidString
            newCertificate.publicKey = publicKey as NSData
            newCertificate.notBefore = (x509Values["notBefore"] as! NSDate)
            newCertificate.notAfter = (x509Values["notAfter"] as! NSDate)

            // Payload

            var payload: [String: String] = [:]
            payload[Certificate.payloadExternalCertificateId] = externalId

            let jsonEncoder = JSONEncoder()
            let jsonData = try? jsonEncoder.encode(payload)

            newCertificate.payload = jsonData! as NSData
        }

        //

        ModelsDataController.save()
    }

}
