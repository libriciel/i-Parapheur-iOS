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
import SwiftMessages

class StringsUtils: NSObject {


    static let dateFormatAnnotation = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    static let dateFormatIso8601 = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    static let dateFormatPrettyPrint = "'le 'dd/MM/yyyy' à 'HH'h'mm"


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


    @objc class func cleanupServerName(url: String) -> String {

        // Removing space
        // TODO Adrien : add special character restrictions tests ?

        var result = url.replacingOccurrences(of: " ", with: "")

        // Getting the server name
        // Regex :	- ignore everything before "://" (if exists)					^(?:.*:\/\/)*
        //			- then ignore following "m-" or "m." (if exists)				(?:m[-\\.])*
        //			- then catch every char but "/"									([^\/]*)
        //			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
        let regex = try! NSRegularExpression(pattern: "^(?:.*:\\/\\/)*(?:m[-\\.])*([^\\/]*)(?:\\/.*)*$",
                                             options: .caseInsensitive)

        let match = regex.firstMatch(in: result,
                                     options: [],
                                     range: NSMakeRange(0, result.count))

        if (match != nil) {
            result = String(result[Range(match!.range(at: 1), in: result)!])
        }

        return result
    }


    class func trim(string: String) -> String {
        let tempString = string.replacingOccurrences(of: "\n", with: "")
        return tempString.replacingOccurrences(of: " ", with: "")
    }


    class func serializeAnnotationDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormatAnnotation
        return dateFormatter.string(from: date)
    }


    class func deserializeAnnotationDate(string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormatAnnotation
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
        dateFormatter.dateFormat = dateFormatPrettyPrint
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


    @objc class func decodeUrlString(encodedString: String) -> String {
        var result = encodedString.replacingOccurrences(of: "+", with: " ")
        result = result.removingPercentEncoding!
        return result
    }

    /**
        For some reason, the commonName, sometimes, isn't parsed.
        Working around the bug is way easier than fix the actual ASN1 parsing.
     */
    @objc class func cleanupX509CertificateValues(_ dict: NSDictionary) -> NSMutableDictionary {
        let result = dict.mutableCopy() as! NSMutableDictionary

        if ((dict["commonName"] == nil) || (dict["commonName"] as! String).isEmpty) {
            if (dict["subject"] != nil) {

                let issuerName = dict["subject"] as! String
                let regex = try? NSRegularExpression(pattern: "CN=(.*?),", options: .caseInsensitive)
                let matches = regex?.matches(in: issuerName, options: [], range: NSRange(location: 0, length: issuerName.count))

                if let match = matches?.first {
                    if let swiftRange = Range(match.range(at: 1), in: issuerName) {
                        result["commonName"] = issuerName[swiftRange]
                    }
                }
            }
        }

        return result
    }

}
