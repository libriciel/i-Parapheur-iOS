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

    static let ANNOTATION_TIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    static let ISO_8601_FORMAT = "yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    static let PRETTY_PRINT_TIME_FORMAT = "'le 'dd/mm/yyyy' à 'HH'h'mm";


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


    class func trim(string: String) -> String {
        let tempString = string.replacingOccurrences(of: "\n", with: "")
        return tempString.replacingOccurrences(of: " ", with: "")
    }


    class func serializeAnnotationDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ANNOTATION_TIME_FORMAT
        return dateFormatter.string(from: date)
    }


    class func deserializeAnnotationDate(string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ANNOTATION_TIME_FORMAT
        return dateFormatter.date(from: string)!
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


    @objc class func prettyPrint(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = PRETTY_PRINT_TIME_FORMAT
        return dateFormatter.string(from: date)
    }


    class func split(string: String,
                     length: Int) -> [String] {

        var startIndex = string.startIndex
        var results = [Substring]()

        while startIndex < string.endIndex {
            let endIndex = string.index(startIndex, offsetBy: length, limitedBy: string.endIndex) ?? string.endIndex
            results.append(string[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map {
            String($0)
        }
    }


    class func toDataList(base64StringList: [String]) -> [Data] {

        var dataToSignList: [Data] = []
        for dataBase64 in base64StringList {
            let rawData = Data(base64Encoded: dataBase64)!
            dataToSignList.append(rawData)
        }

        return dataToSignList
    }


    class func toBase64List(dataList: [Data]) -> [String] {

        var base64List: [String] = []
        for data in dataList {
            base64List.append(data.base64EncodedString())
        }

        return base64List
    }

}