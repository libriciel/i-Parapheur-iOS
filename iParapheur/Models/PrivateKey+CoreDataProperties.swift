//
//  PrivateKey+CoreDataProperties.swift
//  iParapheur
//
//  Created by Adrien on 04/04/2018.
//
//

import Foundation
import CoreData


extension PrivateKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PrivateKey> {
        return NSFetchRequest<PrivateKey>(entityName: "PrivateKey")
    }

    @objc @NSManaged public var caName: String?
    @objc @NSManaged public var commonName: String?
    @objc @NSManaged public var notAfter: NSDate?
    @objc @NSManaged public var notBefore: NSDate?
    @objc @NSManaged public var p12Filename: String?
    @objc @NSManaged public var publicKey: NSData?
    @objc @NSManaged public var serialNumber: String?

}
