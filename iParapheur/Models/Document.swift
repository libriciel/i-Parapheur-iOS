/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
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


class Document: NSObject, Decodable {

    @objc let identifier: String
    @objc let name: String

    let size: CLong
    let pageCount: Int
    let attestState: Int

    let isMainDocument: Bool
    let isPdfVisual: Bool
    let isLocked: Bool
    let isDeletable: Bool


    // <editor-fold desc="Json methods">

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case size
        case pageCount
        case attestState
        case isMainDocument
        case isPdfVisual = "visuelPdf"
        case isLocked
        case isDeletable = "canDelete"
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try values.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "(vide)"

        size = try values.decodeIfPresent(Int.self, forKey: .size) ?? -1
        pageCount = try values.decodeIfPresent(Int.self, forKey: .pageCount) ?? -1
        attestState = try values.decodeIfPresent(Int.self, forKey: .attestState) ?? 0

        isMainDocument = try values.decodeIfPresent(Bool.self, forKey: .isMainDocument) ?? false
        isPdfVisual = try values.decodeIfPresent(Bool.self, forKey: .isPdfVisual) ?? false
        isLocked = try values.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isDeletable = try values.decodeIfPresent(Bool.self, forKey: .isDeletable) ?? false
    }

    // </editor-fold desc="Json methods">

}
