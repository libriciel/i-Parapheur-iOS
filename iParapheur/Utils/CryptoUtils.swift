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
import SSZipArchive
import UIKit
import AEXML


@objc class CryptoUtils: NSObject {

    static private let CERTIFICATE_TEMP_SUB_DIRECTORY = "Certificate_temp/"


    class func checkCertificate(pendingDerFile: URL!) -> Bool {

        // TODO : Check this previous version.

//        // create a policy that ignores hostname
//        let domain: CFString? = nil
//        let policy: SecPolicy = SecPolicyCreateSSL(true, domain)
//
//        // takes all certificates from existing trust
//        let numCerts = SecTrustGetCertificateCount(trust)
//        var certs: [SecCertificate] = [SecCertificate]()
//        for i in 0..<numCerts {
//            // takeUnretainedValue
//            let c: SecCertificate? = SecTrustGetCertificateAtIndex(trust, i)
//            certs.append(c!)
//        }
//
//        // and adds them to the new policy
//        var newTrust: SecTrust? = nil
//        var err: OSStatus = SecTrustCreateWithCertificates(certs as CFTypeRef, policy, &newTrust)
//        if (err != noErr) {
//            print("Could not create trust")
//        }

        // Retrieving test certificate

        let pendingCertificateData = NSData(contentsOf: pendingDerFile!)
        if (pendingCertificateData == nil) {
            return false
        }

        let pendingSecCertificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, pendingCertificateData!)
        if (pendingSecCertificateRef == nil) {
            return false
        }

        var pendingSecTrust: SecTrust?
        let status = SecTrustCreateWithCertificates(pendingSecCertificateRef!, SecPolicyCreateBasicX509(), &pendingSecTrust)
        if (status != errSecSuccess) {
            return false
        }

        // Retrieving root AC certificate

        let authorityDerFile = Bundle.main.url(forResource: "acmobile", withExtension: "der")!
        let authorityCertificateData = NSData(contentsOf: authorityDerFile)
        let authoritySecCertificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, authorityCertificateData!)

        // Test and result

        SecTrustSetAnchorCertificates(pendingSecTrust!, [authoritySecCertificateRef] as CFArray)
        SecTrustSetAnchorCertificatesOnly(pendingSecTrust!, true)

        var secResult = SecTrustResultType.invalid
        return (SecTrustEvaluate(pendingSecTrust!, &secResult) == errSecSuccess)
    }


    @objc class func getCertificateTempDirectory() -> NSURL {

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let tempDir = documentsDirectory.appendingPathComponent(CryptoUtils.CERTIFICATE_TEMP_SUB_DIRECTORY,
                                                                isDirectory: true)

        try? FileManager.default.createDirectory(atPath: tempDir.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)

        return tempDir as NSURL
    }


    @objc class func moveCertificate(url: NSURL!) {

        let destZipPath = getCertificateTempDirectory().appendingPathComponent(url.lastPathComponent!)!

        try? FileManager.default.moveItem(at: url as URL,
                                          to: destZipPath as URL)

        try? SSZipArchive.unzipFile(atPath: destZipPath.path,
                                    toDestination: getCertificateTempDirectory().path!,
                                    overwrite: true,
                                    password: nil)

        try? FileManager.default.removeItem(at: destZipPath)
    }


    @objc class func dataToBase64String(data: NSData) -> NSString {
        print("Adrien data   : \(data)")
        let result = (data as Data).base64EncodedString(options : .endLineWithLineFeed)
        print("Adrien result : \(result)")
        return result as NSString;
    }


    @objc class func buildXadesSignWrapper() -> String {

        // create XML Document
        let rootDocument = AEXMLDocument()
        let documentDetachedExternalSignature = rootDocument.addChild(name: "DocumentDetachedExternalSignature")

        let signature = documentDetachedExternalSignature.addChild(name: "ds:Signature",
                                                                   attributes: [
                                                                       "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
                                                                       "Id": "IDF2017-05-17T08-29-45.35_SIG_1"
                                                                   ])

        let signedInfo = signature.addChild(name: "ds:SignedInfo")
        signedInfo.addChild(name: "ds:CanonicalizationMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        signedInfo.addChild(name: "ds:SignatureMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#rsa-sha1"])

        let reference1 = signedInfo.addChild(name: "ds:Reference",
                                             attributes: ["URI": "#IDF2017-05-17T08-29-45.35"])

        let transforms1 = reference1.addChild(name: "ds:Transforms")
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#enveloped-signature"])
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])

        reference1.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference1.addChild(name: "ds:DigestValue",
                            value: "IoD02noHfnPPyW32kLXkqjs67pg=")

        let reference2 = signedInfo.addChild(name: "ds:Reference",
                                             attributes: ["Type": "http://uri.etsi.org/01903/v1.1.1#SignedProperties",
                                                          "URI": "#IDF2017-05-17T08-29-45.35_SIG_1_SP"])

        let transforms2 = reference2.addChild(name: "ds:Transforms")
        transforms2.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        reference2.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference2.addChild(name: "ds:DigestValue",
                            value: "ompiAGv4kR9H6fLtUMios2m0Eok=")

        // prints the same XML structure as original
        return rootDocument.xml
    }

}
