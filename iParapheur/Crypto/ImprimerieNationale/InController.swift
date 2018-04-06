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


extension Notification.Name {
    static let certificateImport = Notification.Name("CertificateImport")
}


@objc class InController: NSObject {


    // <editor-fold desc="Middleware">

    class func getTokenData() {

        let urlString = "inmiddleware://getTokenData/{" +
                "\"responseScheme\":\"iparapheur\"," +
                "\"tokenExpectedData\":{\"middleware\":\"all\",\"token\":\"all\",\"certificates\":\"all\"}" +
                "}"
        let urlEncodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlEncodedString)!

        UIApplication.shared.open(url, completionHandler: { (result) in
            if result {
                print("Result OK")
            }
        })
    }

    // </editor-fold desc="Middleware">


    @objc class func parseIntent(url: URL) -> Bool {

        if (url.scheme != "iparapheur") {
            return false
        }

        let jsonDecoder = JSONDecoder()
        let croppedUrl = String(url.path.dropFirst())

        guard let tokenData = try? jsonDecoder.decode(InTokenData.self, from: croppedUrl.data(using: .utf8)!) else {
            return false
        }

        importCertificate(token: tokenData)
        NotificationCenter.default.post(name: .certificateImport, object: nil)

        return true;
    }

    class func importCertificate(token: InTokenData) {

        let context = ModelsDataController.context!
        let newCertificate = NSEntityDescription.insertNewObject(forEntityName: Certificate.ENTITY_NAME, into: context) as! Certificate

        newCertificate.sourceType = .imprimerieNationale
        newCertificate.caName = token.manufacturerId
        newCertificate.commonName = "\(token.manufacturerId) \(token.serialNumber)"
        newCertificate.serialNumber = token.serialNumber
        // newCertificate.publicKey = token.certificates[0]
        newCertificate.identifier = UUID().uuidString

        ModelsDataController.save()
    }

}
