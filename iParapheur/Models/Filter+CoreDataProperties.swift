//
//  Filter+CoreDataProperties.swift
//  
//
//  Created by Adrien Bricchi on 21/11/2017.
//
//

import Foundation
import CoreData


extension Filter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Filter> {
        return NSFetchRequest<Filter>(entityName: "Filter")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var title: String?
    @NSManaged public var typeList: [String]?
    @NSManaged public var subTypeList: [String]?
    @NSManaged public var state: String?
    @NSManaged public var beginDate: NSDate?
    @NSManaged public var endDate: NSDate?

}
