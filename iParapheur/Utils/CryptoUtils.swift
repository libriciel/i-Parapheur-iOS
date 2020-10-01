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
import SSZipArchive
import UIKit
import AEXML
import Security
import CryptoSwift
import os


extension Notification.Name {

    static let signatureResult = Notification.Name("signatureResult")

}

class CryptoUtils: NSObject {

    static public let notifSignedData = "signedData"
    static public let notifSignatureIndex = "signatureIndex"
    static public let notifFolderId = "dossierId"
    static public let pkcs15Asn1HexPrefix = "3021300906052B0E03021A05000414"

    static private let certificateTempSubDirectory = "Certificate_temp/"
    static private let publicKeyBeginCertificate = "-----BEGIN CERTIFICATE-----"
    static private let publicKeyEndCertificate = "-----END CERTIFICATE-----"
    static private let pkcs7Begin = "-----BEGIN PKCS7-----"
    static private let pkcs7End = "-----END PKCS7-----"
    static private let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }


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
        let tempDir = documentsDirectory.appendingPathComponent(CryptoUtils.certificateTempSubDirectory,
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

        return cleanedSignature as NSString
    }


    @objc class func cleanupPublicKey(publicKey: String) -> String {

        var result = publicKey.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: publicKeyBeginCertificate)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: publicKeyEndCertificate)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    @objc class func cleanupPkcs7(signature: String) -> String {

        var result = signature.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: pkcs7Begin)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: pkcs7End)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    @objc class func wrappedPem(publicKey: String) -> String {

        let cleanedString = cleanupPublicKey(publicKey: publicKey)

        var result = ""
        result.append("\(publicKeyBeginCertificate)\n")
        for split in StringsUtils.split(string: cleanedString, length: 64) {
            result.append("\(split)\n")
        }
        result.append("\(publicKeyEndCertificate)")
        return result
    }


    class func wrappedPkcs7(pkcs7: String) -> String {

        let cleanedString = cleanupPkcs7(signature: pkcs7)

        var result = ""
        result.append("\(pkcs7Begin)\n")
        for split in StringsUtils.split(string: cleanedString, length: 64) {
            result.append("\(split)\n")
        }
        result.append("\(pkcs7End)")
        return result
    }


    @objc class func cleanupSignature(string: String) -> String {

        var result = string.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: pkcs7Begin)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: pkcs7End)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }


    class func p12LocalUrl(certificate: Certificate) -> URL? {

        // Retrieving signature certificate

        let fileManager = FileManager()
        guard let pathURL = try? fileManager.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true) else {
            return nil
        }

        let jsonDecoder = JSONDecoder()
        let payload: [String: String] = try! jsonDecoder.decode([String: String].self, from: certificate.payload! as Data)
        let p12Name = payload[Certificate.payloadP12FileName]!

        return pathURL.appendingPathComponent(p12Name)
    }


    class func signWithP12(folderId: String,
                           signInfoList: [SignInfo],
                           certificate: Certificate,
                           password: String) {

        guard let p12Url = p12LocalUrl(certificate: certificate) else {
            ViewUtils.logError(message: "Impossible de récupérer le certificat",
                               title: "Erreur à la signature")
            return
        }

        // Building signature response

                    do {
            for signInfo in signInfoList {
                for hash in signInfo.dataToSignBase64List {
                    var signedHash = try CryptoUtils.rsaSign(data: NSData(base64Encoded: hash)!,
                                                                     keyFileUrl: p12Url,
                                                             signatureAlgorithm: .sha256WithRsa,
                                                                     password: password)

                            signedHash = signedHash.replacingOccurrences(of: "\n", with: "")
                    signInfo.signaturesBase64List.append(signedHash)
                }
                        }

                        NotificationCenter.default.post(name: .signatureResult,
                                                        object: nil,
                                                        userInfo: [
                                                notifSignedData: signInfoList,
                                                notifFolderId: folderId
                                                        ])

                    } catch let error {
                        ViewUtils.logError(message: error.localizedDescription as NSString,
                                           title: "Erreur à la signature")
                    }
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
            result.append(hexAlphabet[Int(value / 16)])
            result.append(hexAlphabet[Int(value % 16)])
        }))
    }

}
