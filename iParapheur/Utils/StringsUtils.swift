/*
 * Copyright 2012-2017, Libriciel SCOP.
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
import SwiftMessages

@objc class StringsUtils: NSObject {

    static private let ANNOTATION_TIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'"


    @objc class func getMessage(error: NSError) -> NSString {
        switch (Int32(error.code)) {

        case CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue:
            return "La connexion Internet a été perdue."

        case CFNetworkErrors.cfurlErrorBadServerResponse.rawValue:
            return "Erreur d'authentification"

        case CFNetworkErrors.cfurlErrorCannotLoadFromNetwork.rawValue...CFNetworkErrors.cfurlErrorSecureConnectionFailed.rawValue,
             CFNetworkErrors.cfurlErrorCancelled.rawValue:
            return "Le serveur n'est pas valide"

        case CFNetworkErrors.cfurlErrorUserAuthenticationRequired.rawValue:
            return "Échec d'authentification"

        case CFNetworkErrors.cfurlErrorCannotFindHost.rawValue,
             CFNetworkErrors.cfurlErrorBadServerResponse.rawValue:
            return "Le serveur est introuvable"

        case CFNetworkErrors.cfurlErrorTimedOut.rawValue:
            return "Le serveur ne répond pas dans le délai imparti"

        default:
            return error.localizedDescription as NSString
        }
    }

    class func deserializeAnnotationDate(string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ANNOTATION_TIME_FORMAT
        return dateFormatter.date(from: string)!
    }

    class func serializeAnnotationDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ANNOTATION_TIME_FORMAT
        return dateFormatter.string(from: date)
    }

    class func parseNumberOrString<T>(container: KeyedDecodingContainer<T>,
                                      key: KeyedDecodingContainer<T>.Key) -> Float {

        let result: Float?

        do {
            let string = try container.decodeIfPresent(String.self, forKey: key)
            result = (string! as NSString).floatValue
        } catch {
            result = try! container.decodeIfPresent(Float.self, forKey: key)
        }

        return result!
    }

}
