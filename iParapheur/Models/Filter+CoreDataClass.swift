//
//  Filter+CoreDataClass.swift
//  
//
//  Created by Adrien Bricchi on 21/11/2017.
//
//

import Foundation
import CoreData


public class Filter: NSManagedObject, Encodable {


	static let EntityName: String! = "Filter"


    // MARK: - JSON

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case typeList
        case subTypeList
        case state
        case beginDate
        case endDate
    }

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(title, forKey: .title)
        try container.encode(typeList, forKey: .typeList)
        try container.encode(subTypeList, forKey: .subTypeList)
        try container.encode(state, forKey: .state)
		try container.encode(beginDate! as Date, forKey: .beginDate)
		try container.encode(endDate! as Date, forKey: .endDate)
    }

}
