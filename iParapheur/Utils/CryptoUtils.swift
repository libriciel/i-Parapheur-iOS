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


@objc class CryptoUtils: NSObject {


    static private let CERTIFICATE_TEMP_SUB_DIRECTORY = "Certificate_temp/"
    static private let PUBLIC_KEY_BEGIN_CERTIFICATE = "-----BEGIN CERTIFICATE-----"
    static private let PUBLIC_KEY_END_CERTIFICATE = "-----END CERTIFICATE-----"
    static private let PKCS7_BEGIN = "-----PKCS7 BEGIN-----"
    static private let PKCS7_END = "-----PKCS7 BEGIN-----"


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
        let cleanedSignature = cleanupSignature(publicKey: pollutedSignature!)

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

        return result
    }


    @objc class func cleanupSignature(publicKey: String) -> String {

        print("Adrien :::: \(publicKey)")

        var result = publicKey.trimmingCharacters(in: CharacterSet.whitespaces)
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        result = result.replacingOccurrences(of: "\n", with: "")

        if let index = result.range(of: PKCS7_BEGIN)?.upperBound {
            result = String(result.suffix(from: index))
        }

        if let index = result.range(of: PKCS7_END)?.lowerBound {
            result = String(result.prefix(upTo: index))
        }

        print("Adrien :::: \(result)")
        return result
    }


//    class func loadSecKey(p12path: String,
//                          password: String) -> SecKey? {
//
//        let fileManager = FileManager.default
//        if fileManager.fileExists(atPath: p12path){
//
//            let p12Data: NSData = NSData(contentsOfFile: p12path)!
//            let key : NSString = kSecImportExportPassphrase as NSString
//            let options : NSDictionary = [key : password]
//
//            var privateKeyRef: SecKey? = nil
//            var items : CFArray?
//            var securityError: OSStatus = SecPKCS12Import(p12Data, options, &items)
//            let identityDict: CFDictionary = CFArrayGetValueAtIndex(items, 0) as! CFDictionary
//            let identityApp: SecIdentity = CFDictionaryGetValue(identityDict, kSecImportItemIdentity) as! SecIdentity;
//            var securityError2 = SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
//        }
//
//        return nil
//    }
//
//    @objc class func pkcs1Sign(data: Data,
//                               privateKeyPath: String,
//                               password: String) -> String? {
//
//        let privateSecKey = ADLKeyStore.loadPrivateKeySecRef(withPath: privateKeyPath,
//                                                             andPassword: password) as! SecKey
//
//        var error: Unmanaged<CFError>?
//        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA1
//        guard let signature = SecKeyCreateSignature(privateSecKey,
//                                                    algorithm,
//                                                    data as CFData,
//                                                    &error) as Data? else {
//
//            print("Signature Adrien PKCS#1 : Something went wrong, bro")
//            return nil
//        }
//
//        let result = String(data: signature, encoding: .utf8)
//        print("Signature Adrien PKCS#1 : \(result)")
//        return result;
//    }


    @objc class func rsaSign(data: NSData,
                             keyFilePath: String,
                             password: String?) -> String? {

        let secKey = CryptoUtils.pkcs12ReadKey(path: keyFilePath,
                                               password: password)

        let result = CryptoUtils.rsaSign(data: data,
                                         privateKey: secKey!)

        return result
    }


    class func rsaSign(data: NSData,
                       privateKey: SecKey!) -> String? {

        let signedData = NSMutableData(length: SecKeyGetBlockSize(privateKey))!
        var signedDataLength = signedData.length

        let err: OSStatus = SecKeyRawSign(privateKey,
                                          SecPadding.PKCS1SHA1,
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


    class func pkcs12ReadKey(path keyFilePath: String,
                             password: String?) -> SecKey? {

        var p12KeyFileContent: CFData?
        do {
            p12KeyFileContent = try Data(contentsOf: URL(fileURLWithPath: keyFilePath),
                                         options: .alwaysMapped) as CFData
        }
        catch {
            NSLog("Cannot read PKCS12 file from \(keyFilePath)")
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

        print("SecIdentityCopyPrivateKey success : \(privateKey.pointee)")
        return privateKey.pointee
    }


    class func sha1Base64(string: String) -> String {
        let hexSha1 = string.sha1()
        let sha1Data = CryptoUtils.dataWithHexString(hex: hexSha1)
        return sha1Data.base64EncodedString()
    }


    class func sha1Base64(data: Data) -> String {
        let sha1Data = data.sha1()
        return sha1Data.base64EncodedString()
    }


    class func dataWithHexString(hex: String) -> Data {
        var hex = hex
        var data = Data()
        while (hex.count > 0) {
            let c: String = hex.substring(to: hex.index(hex.startIndex, offsetBy: 2))
            hex = hex.substring(from: hex.index(hex.startIndex, offsetBy: 2))
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return data
    }

}
