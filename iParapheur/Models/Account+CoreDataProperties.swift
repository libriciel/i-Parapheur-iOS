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

    @objc @NSManaged var id: String?
    @NSManaged var isVisible: NSNumber?
    @objc @NSManaged var login: String?
    @objc @NSManaged var password: String?
    @NSManaged var title: String?
    @objc @NSManaged var url: String?

}
