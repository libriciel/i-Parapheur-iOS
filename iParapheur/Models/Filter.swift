/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
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
import Gloss


@objc class Filter: NSObject, Glossy {

    // JSON field names
    private static let ID = "id"
    private static let NAME = "name"
    private static let TITLE = "title"
    private static let TYPE_LIST = "typeList"
    private static let SUBTYPE_LIST = "subTypeList"
    private static let STATE = "state"
    private static let BEGIN_DATE = "beginDate"
    private static let END_DATE = "endDate"

    // API values
    static let REQUEST_JSON_FILTER_TYPE_METIER = "ph:typeMetier"
    static let REQUEST_JSON_FILTER_SOUS_TYPE_METIER = "ph:soustypeMetier"
    static let REQUEST_JSON_FILTER_TITLE = "cm:title"
    static let REQUEST_JSON_FILTER_AND = "and"
    static let REQUEST_JSON_FILTER_OR = "or"
    static let EDIT_FILTER_ID = "edit-filter"
    static let DEFAULT_STATE = State.A_TRAITER


    let id: String
    let name: String
    let title: String
    let typeList: [String]
    let subTypeList: [String]
    let state: State
    let beginDate: Date?
    let endDate: Date?


    // MARK: - Glossy


    required init?(json: JSON) {

        id = (Filter.ID <~~ json) ?? ""
        name = (Filter.NAME <~~ json) ?? ""
        title = (Filter.TITLE <~~ json) ?? ""
        typeList = (Filter.TYPE_LIST <~~ json) ?? []
        subTypeList = (Filter.SUBTYPE_LIST <~~ json) ?? []
        state = (Filter.STATE <~~ json) ?? State.A_TRAITER
        beginDate = (Filter.BEGIN_DATE <~~ json)
        endDate = (Filter.END_DATE <~~ json)
    }


    func toJSON() -> JSON? {
        return jsonify([
                           Filter.ID ~~> self.id,
                           Filter.NAME ~~> self.name,
                           Filter.TITLE ~~> self.title,
                           Filter.TYPE_LIST ~~> self.typeList,
                           Filter.SUBTYPE_LIST ~~> self.subTypeList,
                           Filter.STATE ~~> self.state.rawValue,
                           Filter.BEGIN_DATE ~~> self.beginDate,
                           Filter.END_DATE ~~> self.endDate
                       ])
    }

}