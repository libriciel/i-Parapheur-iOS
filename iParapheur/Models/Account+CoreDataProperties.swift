//
//  Account+CoreDataProperties.swift
//  iParapheur
//
//  Created by Adrien Bricchi on 20/10/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Account {

    @NSManaged var id: String?
    @NSManaged var isVisible: NSNumber?
    @NSManaged var login: String?
    @NSManaged var password: String?
    @NSManaged var title: String?
    @NSManaged var url: String?

}
