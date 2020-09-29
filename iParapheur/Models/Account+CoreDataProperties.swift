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
import CoreData


extension Account {

    static let entityName = "Account"
    @objc static let preferenceKeySelectedAccount = "selected_account"
    static let legacyId = "FirstAccountId"
    @objc static let demoId = "DemoAccountId"
    static let demoTitle = "iParapheur demo"
    static let demoUrl = "iparapheur-partenaires.libriciel.fr"
    static let demoLogin = "admin@demo"
    static let demoPass = "admin"

    @NSManaged var id: String?
    @NSManaged var isVisible: NSNumber?
    @NSManaged var login: String?
    @NSManaged var password: String?
    @NSManaged var title: String?
    @NSManaged var url: String?

}
