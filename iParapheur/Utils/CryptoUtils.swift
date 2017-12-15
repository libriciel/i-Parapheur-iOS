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
    static private let PUBLIC_KEY_BEGIN_CERTIFICATE = "-----BEGIN CERTIFICATE-----"
    static private let PUBLIC_KEY_END_CERTIFICATE = "-----END CERTIFICATE-----"


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
        let result = (data as Data).base64EncodedString(options: .endLineWithLineFeed)
        print("Adrien result : \(result)")
        return result as NSString;
    }


    @objc class func buildXadesEnveloppedSignWrapper(privateKey: PrivateKey,
                                                     signatureValue: String,
                                                     signInfo: SignInfo) -> String {

        // Build up some data

        let pollutedPublicKey = String(data: privateKey.publicKey, encoding: String.Encoding.utf8)
        let cleanedPublicKey = CryptoUtils.cleanupPublicKey(publicKey: pollutedPublicKey!)
        let cleanedPublicKeySha1 = CryptoUtils.hashInSHA1(string: cleanedPublicKey)


        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZ"
        let currentDateIso8601 = dateFormatter.string(from: Date())

        print("Adrien - pollutedPublicKey    \(pollutedPublicKey)")
        print("Adrien - cleanedPublicKey     \(cleanedPublicKey)")
        print("Adrien - cleanedPublicKeySha1 \(cleanedPublicKeySha1)")
        print("Adrien - currentDateIso8601   \(currentDateIso8601)")

        // Build-up - First round

        let keyInfoNode = CryptoUtils.buildXadesEnvKeyInfo(publicKey: cleanedPublicKey)

        let signedSignaturePropertiesNode = CryptoUtils.buildXadesEnvSignedSignatureProperties(signInfo: signInfo,
                                                                                               currentDateIso8601: currentDateIso8601,
                                                                                               privateKey: privateKey,
                                                                                               publicKeySha1: cleanedPublicKeySha1)

        // Compute

        let signaturePropertiesString = signedSignaturePropertiesNode.xmlCompact
        let signaturePropertiesHash = CryptoUtils.hashInSHA1(string: signaturePropertiesString)

        print("Adrien signedPropertiesHash - \(signaturePropertiesHash)")
        let actualSignature = "oooOOOooo"

        // Build-up - Second phase

        let signedInfoNode = CryptoUtils.buildXadesEnvSignedInfo(signInfo: signInfo,
                                                                 signedPropertiesHash: signaturePropertiesHash)

        let signatureValueNode = CryptoUtils.buildXadesSignatureValue(signInfo: signInfo,
                                                                      signature: actualSignature)

        let objectNode = CryptoUtils.buildXadesEnvObject(signInfo: signInfo,
                                                         signedSignaturePropertiesNode: signedSignaturePropertiesNode)

        // Wrap-up everything

        let rootDocument = AEXMLDocument()
        let documentDetachedExternalSignature = rootDocument.addChild(name: "DocumentDetachedExternalSignature")
        let signature = documentDetachedExternalSignature.addChild(name: "ds:Signature",
                                                                   attributes: [
                                                                       "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
                                                                       "Id": "IDF2017-05-17T08-29-45.35_SIG_1"
                                                                   ])

        signature.addChild(signedInfoNode)
        signature.addChild(signatureValueNode)
        signature.addChild(keyInfoNode)
        signature.addChild(objectNode)

        print("rootDocument.xmlCompact :: \(rootDocument.xmlCompact)")
        return rootDocument.xmlCompact
    }


    class func buildXadesEnvSignedInfo(signInfo: SignInfo,
                                       signedPropertiesHash: String) -> AEXMLElement {

        let rootDocument = AEXMLDocument()

        let signedInfo = rootDocument.addChild(name: "ds:SignedInfo")
        signedInfo.addChild(name: "ds:CanonicalizationMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        signedInfo.addChild(name: "ds:SignatureMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#rsa-sha1"])

        let reference1 = signedInfo.addChild(name: "ds:Reference",
                                             attributes: ["URI": "#\(signInfo.pesId!)"])

        let transforms1 = reference1.addChild(name: "ds:Transforms")
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#enveloped-signature"])
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])

        reference1.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference1.addChild(name: "ds:DigestValue",
                            value: signInfo.hashToSign)

        let reference2 = signedInfo.addChild(name: "ds:Reference",
                                             attributes: ["Type": "http://uri.etsi.org/01903/v1.1.1#SignedProperties",
                                                          "URI": "#\(signInfo.pesId!)_SIG_1_SP"])

        let transforms2 = reference2.addChild(name: "ds:Transforms")
        transforms2.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        reference2.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference2.addChild(name: "ds:DigestValue",
                            value: signedPropertiesHash)

        return rootDocument.root
    }


    class func buildXadesSignatureValue(signInfo: SignInfo,
                                        signature: String) -> AEXMLElement {

        let rootDocument = AEXMLDocument()

        let xmlSignatureValueNode = rootDocument.addChild(name: "ds:SignatureValue",
                                                          value: signature,
                                                          attributes: ["Id": "\(signInfo.pesId!)_SIG_1_SV", ])

        return rootDocument.root
    }


    class func buildXadesEnvKeyInfo(publicKey: String) -> AEXMLElement {

        let rootDocument = AEXMLDocument()

        let keyInfo = rootDocument.addChild(name: "ds:KeyInfo")
        let x509data = keyInfo.addChild(name: "ds:X509Data")
        x509data.addChild(name: "ds:X509Certificate", value: publicKey)

        return rootDocument.root
    }


    class func buildXadesEnvSignedSignatureProperties(signInfo: SignInfo,
                                                      currentDateIso8601: String,
                                                      privateKey: PrivateKey,
                                                      publicKeySha1: String) -> AEXMLElement {

        let rootDocument = AEXMLDocument()

        let signedProperties = rootDocument.addChild(name: "xad:SignedProperties",
                                                     attributes: ["Id": "\(signInfo.pesId!)_SIG_1_SP"])

        let signedSignatureProperties = signedProperties.addChild(name: "xad:SignedSignatureProperties")
        signedSignatureProperties.addChild(name: "xad:SigningTime", value: currentDateIso8601)

        let signingCertificate = signedSignatureProperties.addChild(name: "xad:SigningCertificate")
        let cert = signingCertificate.addChild(name: "xad:Cert")

        let certDigest = cert.addChild(name: "xad:CertDigest")
        certDigest.addChild(name: "xad:DigestMethod", attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        certDigest.addChild(name: "xad:DigestValue", value: publicKeySha1)

        let issuerSerial = cert.addChild(name: "xad:IssuerSerial")
        issuerSerial.addChild(name: "ds:X509IssuerName", value: privateKey.caName)
        issuerSerial.addChild(name: "ds:X509SerialNumber", value: privateKey.serialNumber)

        let signaturePolicyIdentifier = signedSignatureProperties.addChild(name: "xad:SignaturePolicyIdentifier")
        let signaturePolicyId = signaturePolicyIdentifier.addChild(name: "xad:SignaturePolicyId")

        let sigPolicyId = signaturePolicyId.addChild(name: "xad:SigPolicyId")
        sigPolicyId.addChild(name: "xad:Identifier", value: signInfo.pesPolicyId)
        sigPolicyId.addChild(name: "xad:Description", value: signInfo.pesPolicyDesc)

        let sigPolicyHash = signaturePolicyId.addChild(name: "xad:SigPolicyHash")
        sigPolicyHash.addChild(name: "xad:DigestMethod", attributes:["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        sigPolicyHash.addChild(name: "xad:DigestValue", value:signInfo.pesPolicyHash)

        let sigPolicyQualifiers = signaturePolicyId.addChild(name: "xad:SigPolicyQualifiers")
        let sigPolicyQualifier = sigPolicyQualifiers.addChild(name: "xad:SigPolicyQualifier")
        sigPolicyQualifier.addChild(name: "xad:SPURI", value: "http://www.s2low.org/PolitiqueSignature-Agent")

        let signatureProductionPlace = signedSignatureProperties.addChild(name: "xad:SignatureProductionPlace")
        signatureProductionPlace.addChild(name: "xad:City", value: signInfo.pesCity)
        signatureProductionPlace.addChild(name: "xad:PostalCode", value: signInfo.pesPostalCode)
        signatureProductionPlace.addChild(name: "xad:CountryName", value: signInfo.pesCountryName)

        let signerRole = signedSignatureProperties.addChild(name: "xad:SignerRole")
        let claimedRoles = signerRole.addChild(name: "xad:ClaimedRoles")
        claimedRoles.addChild(name: "xad:ClaimedRole", value: signInfo.pesClaimedRole)

        return rootDocument.root
    }


    class func buildXadesEnvObject(signInfo: SignInfo,
                                   signedSignaturePropertiesNode: AEXMLElement) -> AEXMLElement {

        let rootDocument = AEXMLDocument()

        let objectNode = rootDocument.addChild(name: "ds:Object")
        let qualifyingProperties = objectNode.addChild(name: "xad:QualifyingProperties",
                                                       attributes: ["xmlns:xad": "http://uri.etsi.org/01903/v1.1.1#",
                                                                    "xmlns": "http://uri.etsi.org/01903/v1.1.1#",
                                                                    "Target": "#\(signInfo.pesId!)_SIG_1"])

        qualifyingProperties.addChild(signedSignaturePropertiesNode)

        return rootDocument.root
    }


    @objc class func cleanupPublicKey(publicKey: String) -> String {

        var result = publicKey.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: PUBLIC_KEY_BEGIN_CERTIFICATE)?.upperBound {
			result = String(result.suffix(from: index))
        }

        if let index = result.range(of: PUBLIC_KEY_END_CERTIFICATE)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        return result
    }


    class func hashInSHA1(string: String) -> String {

        let data = string.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))

        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }

        return Data(bytes: digest).base64EncodedString()
    }

}
