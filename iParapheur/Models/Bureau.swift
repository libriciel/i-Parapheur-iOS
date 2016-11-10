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

@objc class Bureau : NSObject, Glossy {

    let name: String?
    let collectivite: String?
    let desc: String?
    let nodeRef: String?
    let shortName: String?
    let image: String?
    let identifier: String?
    let habilitation: Dictionary<String, AnyObject>?

    let enPreparation: Int?
    let enRetard: Int?
    let aArchiver: Int?
    let aTraiter: Int?

    let hasSecretaire: Bool?
    let showAVenir: Bool?
    let isSecretaire: Bool?
    let retournes: Bool?
    let dossiersDelegues: Bool?

    // MARK: - Glossy

    required init?(json: JSON) {
        name = ("name" <~~ json) ?? "(vide)"
        collectivite = "collectivite" <~~ json
        desc = "description" <~~ json
        nodeRef = ("nodeRef" <~~ json) ?? ""
        shortName = "shortName" <~~ json
        image = "image" <~~ json
        identifier = "id" <~~ json
        habilitation = ("habilitation" <~~ json) ?? [:]

        enPreparation = "en-preparation" <~~ json
        enRetard = ("en-retard" <~~ json) ?? 0
        aArchiver = ("a-archiver" <~~ json) ?? 0
        aTraiter = ("a-traiter" <~~ json) ?? 0

        hasSecretaire = ("hasSecretaire" <~~ json) ?? false
        showAVenir = ("show_a_venir" <~~ json) ?? false
        isSecretaire = ("isSecretaire" <~~ json) ?? false
        retournes = ("retournes" <~~ json) ?? false
        dossiersDelegues = ("dossiers-delegues" <~~ json) ?? false
    }

    func toJSON() -> JSON? {
        return nil /* Not used */
    }

    // MARK: - ObjC accessors

    func unwrappedName() -> NSString {
		return NSString(string:name!)
    }

    func unwrappedNodeRef() -> NSString {
		return NSString(string:nodeRef!)
    }

    func unwrappedEnRetard() -> NSNumber {
        return enRetard as! NSNumber
    }

    func unwrappedATraiter() -> NSNumber {
        return aTraiter as! NSNumber
    }

}
