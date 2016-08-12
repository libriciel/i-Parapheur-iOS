/*
* Copyright 2012-2016, Adullact-Projet.
* Contributors : SKROBS (2012)
*
* contact@adullact-projet.coop
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
import UIKit.UITableViewController

class SettingsTableViewController: UITableViewController {

    var items: [String] = ["Comptes", "Certificats", "Filtres", "Informations légales", "Licences tierces"];

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : SettingsTableViewController")
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Adrien test iOS8

//        var manager: AFHTTPSessionManager = AFHTTPSessionManager(baseURL: NSURL(string:"https://m.parapheur.demonstrations.adullact.org"))
//        manager.requestSerializer = AFJSONRequestSerializer() // force serializer to use JSON encoding
//        manager.setSessionDidReceiveAuthenticationChallengeBlock { (session, challenge, credential) -> NSURLSessionAuthChallengeDisposition in
//
//            if SettingsTableViewController.shouldTrustProtectionSpace(challenge, credential: credential) {
//                // shouldTrustProtectionSpace will evaluate the challenge using bundled certificates, and set a value into credential if it succeeds
//                return NSURLSessionAuthChallengeDisposition.UseCredential
//            }
//            return NSURLSessionAuthChallengeDisposition.PerformDefaultHandling
//        }
//
//        manager.GET("/parapheur/api/getApiLevel", parameters: nil, success: {
//            (task: NSURLSessionDataTask!, responseObject: AnyObject!) in
//            print("success")
//
//        }, failure: {
//            (task: NSURLSessionDataTask!, error: NSError!) in
//            print("error")
//        })
    }

    // MARK: UITableViewController

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = self.items[indexPath.row]
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Clicked - plop")
    }

    // MARK: Test function

    class func shouldTrustProtectionSpace(challenge: NSURLAuthenticationChallenge,
                                          var credential: AutoreleasingUnsafeMutablePointer<NSURLCredential?>) -> Bool {
        // note: credential is a reference; any created credential should be sent back using credential.memory

        let protectionSpace: NSURLProtectionSpace = challenge.protectionSpace
        var trust: SecTrustRef = protectionSpace.serverTrust!

        // load the root CA bundled with the app
        let certPath: String? = NSBundle.mainBundle().pathForResource("acmobile", ofType: "der")
        if certPath == nil {
            print("Certificate does not exist!")
            return false
        }

        let certData: NSData = NSData(contentsOfFile: certPath!)!
        // takeUnretainedValue
        let cert: SecCertificateRef? = SecCertificateCreateWithData(kCFAllocatorDefault, certData)

        if cert == nil {
            print("Certificate data could not be loaded. DER format?")
            return false
        }

        // create a policy that ignores hostname
        let domain: CFString? = nil
        // takeRetainedValue
        let policy:SecPolicy = SecPolicyCreateSSL(true, domain)

        // takes all certificates from existing trust
        let numCerts = SecTrustGetCertificateCount(trust)
        var certs: [SecCertificateRef] = [SecCertificateRef]()
        for var i = 0; i < numCerts; i++ {
            // takeUnretainedValue
            let c: SecCertificateRef? = SecTrustGetCertificateAtIndex(trust, i)
            certs.append(c!)
        }

        // and adds them to the new policy
        var newTrust: SecTrust? = nil
        var err: OSStatus = SecTrustCreateWithCertificates(certs, policy, &newTrust)
        if err != noErr {
            print("Could not create trust")
        }
        // TakeUnretainedValue
        trust = newTrust! // replace old trust

        // set root cert
        let rootCerts: [AnyObject] = [cert!]
        err = SecTrustSetAnchorCertificates(trust, rootCerts)

        // evaluate the certificate and product a trustResult
        var trustResult: SecTrustResultType = SecTrustResultType()
        SecTrustEvaluate(trust, &trustResult)

        if Int(trustResult) == Int(kSecTrustResultProceed) || Int(trustResult) == Int(kSecTrustResultUnspecified) {
            // create the credential to be used
            credential.memory = NSURLCredential(trust: trust)
            return true
        }
        return false
    }

}


