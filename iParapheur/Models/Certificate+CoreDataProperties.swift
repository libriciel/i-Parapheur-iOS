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


extension Certificate {

    @objc static let entityName = "Certificate"

    static let payloadExternalCertificateId = "ExternalCertificateId"
    @objc static let payloadP12FileName = "CertificateP12FileName"


    @NSManaged public var caName: String?
    @NSManaged public var commonName: String?
    @NSManaged public var identifier: String?
    @NSManaged public var notAfter: NSDate?
    @NSManaged public var notBefore: NSDate?
    @NSManaged public var publicKey: NSData?
    @NSManaged public var serialNumber: String?
    @NSManaged public var sourceType: CertificateType
    @NSManaged public var payload: NSData?


    convenience init(id: String, type: CertificateType) {
        self.init()

        identifier = id
        sourceType = type

        caName = nil
        commonName = nil
        notAfter = nil
        notBefore = nil
        publicKey = nil
        serialNumber = nil
        payload = nil
    }

}
