//
//  Certificate+CoreDataProperties.swift
//  iParapheur
//
//  Created by Adrien on 05/04/2018.
//
//

import Foundation
import CoreData


extension Certificate {

    static let ENTITY_NAME = "Certificate"
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Certificate> {
        return NSFetchRequest<Certificate>(entityName: ENTITY_NAME)
    }

    @NSManaged public var caName: String?
    @NSManaged public var commonName: String?
    @NSManaged public var notAfter: NSDate?
    @NSManaged public var notBefore: NSDate?
    @NSManaged public var p12Filename: String?
    @NSManaged public var publicKey: NSData?
    @NSManaged public var serialNumber: String?

}
