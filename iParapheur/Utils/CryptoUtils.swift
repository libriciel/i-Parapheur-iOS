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
import Security
import CryptoSwift
import os


extension Notification.Name {

    static let signatureResult = Notification.Name("signatureResult")

}

@objc class CryptoUtils: NSObject {

    static public let NOTIF_SIGNEDDATA = "signedData"
    static public let NOTIF_SIGNATUREINDEX = "signatureIndex"
    static public let NOTIF_DOSSIERID = "dossierId"

    static private let CERTIFICATE_TEMP_SUB_DIRECTORY = "Certificate_temp/"
    static private let PUBLIC_KEY_BEGIN_CERTIFICATE = "-----BEGIN CERTIFICATE-----"
    static private let PUBLIC_KEY_END_CERTIFICATE = "-----END CERTIFICATE-----"
    static private let PKCS7_BEGIN = "-----BEGIN PKCS7-----"
    static private let PKCS7_END = "-----END PKCS7-----"
    static private let HEX_ALPHABET = "0123456789abcdef".unicodeScalars.map {
        $0
    }

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

        // let result = (data as Data).base64EncodedString()

        let pollutedSignature = String(data: data as Data, encoding: .utf8)
        let cleanedSignature = cleanupSignature(string: pollutedSignature!)

        print("dataToBase64String << \(pollutedSignature!)")
        print("dataToBase64String >> \(cleanedSignature)")

        return cleanedSignature as NSString;
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

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    @objc class func cleanupPkcs7(signature: String) -> String {

        var result = signature.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: PKCS7_BEGIN)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: PKCS7_END)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    @objc class func wrappedPem(publicKey: String) -> String {

        let cleanedString = cleanupPublicKey(publicKey: publicKey)

        var result = ""
        result.append("\(PUBLIC_KEY_BEGIN_CERTIFICATE)\n")
        for split in StringsUtils.split(string: cleanedString, length: 64) {
            result.append("\(split)\n")
        }
        result.append("\(PUBLIC_KEY_END_CERTIFICATE)")
        return result
    }


    class func wrappedPkcs7(pkcs7: String) -> String {

        let cleanedString = cleanupPkcs7(signature: pkcs7)

        var result = ""
        result.append("\(PKCS7_BEGIN)\n")
        for split in StringsUtils.split(string: cleanedString, length: 64) {
            result.append("\(split)\n")
        }
        result.append("\(PKCS7_END)")
        return result
    }


    @objc class func cleanupSignature(string: String) -> String {

        var result = string.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: PKCS7_BEGIN)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: PKCS7_END)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    class func signWithP12(hasher: RemoteHasher,
                           certificate: Certificate,
                           password: String) throws {

        // Retrieving signature certificate

        let fileManager = FileManager()
        guard let pathURL = try? fileManager.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true) else {
            throw NSError(domain: "Impossible de récupérer le certificat", code: 0, userInfo: nil)
        }

        let jsonDecoder = JSONDecoder()
        let payload: [String: String] = try! jsonDecoder.decode([String: String].self, from: certificate.payload! as Data)
        let p12Name = payload[Certificate.PAYLOAD_P12_FILENAME]!
        let p12FinalUrl = pathURL.appendingPathComponent(p12Name)

        // Building signature response

        hasher.generateHashToSign(
                onResponse: {
                    (result: DataToSign) in

                    var signedHashList: [Data] = []
                    let dataToSignList: [Data] = StringsUtils.toDataList(base64StringList: result.dataToSignBase64List)
                    for dataToSign in dataToSignList {

                        let data = hasher.mSignatureAlgorithm == .sha1WithRsa ? dataToSign.sha1() : dataToSign.sha256()
                        var signedHash = try? CryptoUtils.rsaSign(data: data as NSData,
                                                                  keyFileUrl: p12FinalUrl,
                                                                  signatureAlgorithm: hasher.mSignatureAlgorithm,
                                                                  password: password)

                        signedHash = signedHash!.replacingOccurrences(of: "\n", with: "")
                        signedHashList.append(Data(base64Encoded: signedHash!)!)
                    }

                    hasher.buildDataToReturn(signatureList: signedHashList,
                                             onResponse:
                                             {
                                                 (resultList: [Data]) in

                                                 NotificationCenter.default.post(name: .signatureResult,
                                                                                 object: nil,
                                                                                 userInfo: [
                                                                                     NOTIF_SIGNEDDATA: resultList,
                                                                                     NOTIF_DOSSIERID: hasher.mDossier.identifier
                                                                                 ])
                                             },
                                             onError: {
                                                 error in
                                             })
                },
                onError: {
                    (error: Error) in
                    //TODO
                })
    }


    class func generateHasherWrappers(signInfo: SignInfo,
                                      dossier: Dossier,
                                      certificate: Certificate,
                                      restClient: RestClient) throws -> RemoteHasher {

        for hashIndex in 0..<signInfo.hashesToSign.count {
            switch signInfo.format {

                case "xades":

//                    let xadesHasher = XadesSha1EnvHasher(signInfo: signInfo,
//                                                         hashIndex: hashIndex,
//                                                         publicKey: certificate.publicKey!.base64EncodedString(),
//                                                         caName: certificate.caName!,
//                                                         serialNumber: certificate.serialNumber!)
//                    hashers.append(xadesHasher)
                    throw NSError(domain: "Ce format (\(signInfo.format)) est obsolète", code: 0, userInfo: nil)


                case "CMS",
                     "PADES",
                     "PADES-basic":

                    let hasher = RemoteHasher(signInfo: signInfo,
                                              publicKeyBase64: certificate.publicKey!.base64EncodedString(),
                                              dossier: dossier,
                                              restClient: restClient,
                                              signatureAlgorithm: .sha1WithRsa)

                    return hasher


                case "xades-env-1.2.2-sha256":

                    let hasher = RemoteHasher(signInfo: signInfo,
                                              publicKeyBase64: certificate.publicKey!.base64EncodedString(),
                                              dossier: dossier,
                                              restClient: restClient,
                                              signatureAlgorithm: .sha256WithRsa)

                    return hasher

                default:
                    print("Ce format (\(signInfo.format)) n'est pas supporté")
            }
        }

        throw NSError(domain: "Ce format (\(signInfo.format)) n'est pas supporté", code: 0, userInfo: nil)
    }


    @objc class func rsaSign(data: NSData,
                             keyFileUrl: URL,
                             signatureAlgorithm: SignatureAlgorithm,
                             password: String?) throws -> String {

        guard let secKey = CryptoUtils.pkcs12ReadKey(path: keyFileUrl,
                                                     password: password) else {
            throw NSError(domain: "Mot de passe invalide ?", code: 0, userInfo: nil)
        }

        guard let result = CryptoUtils.rsaSign(data: data,
                                               signatureAlgorithm: signatureAlgorithm,
                                               privateKey: secKey) else {
            throw NSError(domain: "Erreur inconnue", code: 0, userInfo: nil)
        }

        return result
    }


    class func rsaSign(data: NSData,
                       signatureAlgorithm: SignatureAlgorithm,
                       privateKey: SecKey!) -> String? {

        let signedData = NSMutableData(length: SecKeyGetBlockSize(privateKey))!
        var signedDataLength = signedData.length

        let err: OSStatus = SecKeyRawSign(privateKey,
                                          signatureAlgorithm == SignatureAlgorithm.sha1WithRsa ? SecPadding.PKCS1SHA1 : SecPadding.PKCS1SHA256,
                                          data.bytes.assumingMemoryBound(to: UInt8.self),
                                          data.length,
                                          signedData.mutableBytes.assumingMemoryBound(to: UInt8.self),
                                          &signedDataLength)

        // Result

        if (err == errSecSuccess) {
            return signedData.base64EncodedString()
        }

        return nil
    }


    class func pkcs12ReadKey(path keyFileUrl: URL,
                             password: String?) -> SecKey? {

        var p12KeyFileContent: CFData?
        do {
            try p12KeyFileContent = Data(contentsOf: keyFileUrl,
                                         options: .alwaysMapped) as CFData
        } catch {
            NSLog("Cannot read PKCS12 file from \(keyFileUrl.lastPathComponent)")
            return nil
        }

        let options: CFDictionary = [kSecImportExportPassphrase: password ?? ""] as CFDictionary
        let citems = UnsafeMutablePointer<CFArray?>.allocate(capacity: 1)

        let resultPKCS12Import = SecPKCS12Import(p12KeyFileContent!, options, citems)
        if (resultPKCS12Import != errSecSuccess) {
            return nil
        }

        let items = citems.pointee as NSArray?
        let myIdentityAndTrust = items!.object(at: 0) as! NSDictionary
        let identityKey = String(kSecImportItemIdentity)
        let identity = myIdentityAndTrust[identityKey] as! SecIdentity

        let trustKey = String(kSecImportItemTrust)
        _ = myIdentityAndTrust[trustKey] as! SecTrust

        let privateKey = UnsafeMutablePointer<SecKey?>.allocate(capacity: 1)
        let resultCopyPrivateKey = SecIdentityCopyPrivateKey(identity, privateKey)
        if (resultCopyPrivateKey != errSecSuccess) {
            print("SecIdentityCopyPrivateKey fail")
            return nil
        }

        print("SecIdentityCopyPrivateKey success : \(String(describing: privateKey.pointee))")
        return privateKey.pointee
    }


    class func sha1Base64(string: String) -> String {
        let hexSha1 = string.sha1()
        let sha1Data = CryptoUtils.data(hex: hexSha1)
        return sha1Data.base64EncodedString()
    }


    class func sha1Base64(data: Data) -> String {
        let sha1Data = data.sha1()
        return sha1Data.base64EncodedString()
    }


    class func data(hex: String) -> Data {

        var hex = hex
        var data = Data()

        while (hex.count > 0) {

            let indexTo = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<indexTo])
            let indexFrom = hex.index(hex.startIndex, offsetBy: 2)
            hex = String(hex[indexFrom...])

            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }

        return data
    }


    class func hex(data: Data) -> String {
        return String(data.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(HEX_ALPHABET[Int(value / 16)])
            result.append(HEX_ALPHABET[Int(value % 16)])
        }))
    }

}
