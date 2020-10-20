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
import os


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
        let urlEncodedString = cleanedString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlEncodedString)!

        os_log("Request sent :: %@", type: .debug, cleanedString)
        os_log("Request sent :: %@", type: .debug, url.absoluteString)

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

        os_log("ParseIntent :: %@", type: .info, url.absoluteString)
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
            os_log(" --hex>> %@", type: .info, inSignedData!.signedData)
            os_log(" --b64>> %@", type: .info, signedData.base64EncodedString())

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
