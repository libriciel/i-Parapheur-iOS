//
//  Filter+CoreDataProperties.swift
//  iParapheur
//
//  Created by Adrien on 22/01/2018.
//
//

import Foundation
import CoreData


extension Filter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Filter> {
        return NSFetchRequest<Filter>(entityName: "Filter")
    }

    @NSManaged public var beginDate: NSDate?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var state: String?
    @NSManaged public var subTypeList: NSObject?
    @NSManaged public var title: String?
    @NSManaged public var typeList: NSObject?

}
