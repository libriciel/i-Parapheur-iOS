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
import PDFKit

class AnnotationsUtils: NSObject {


    class func parse(string: String) -> [Annotation] {
        var result = [Annotation]()
        result += AnnotationsUtils.parseApi3(string: string)
        result += AnnotationsUtils.parseApi4(string: string)
        return result
    }


    class func parseApi4(string: String) -> [Annotation] {

        var result = [Annotation]()
        let decoder = JSONDecoder()
        let parsedData = try? decoder.decode([[String: [Int: [Annotation]]]].self, from: string.data(using: .utf8)!)

        if (parsedData == nil) {
            return result
        }

        for stepDict in parsedData! {
            for documentDict in stepDict {
                for pageDict in documentDict.value {
                    for annotation in pageDict.value {
                        annotation.documentId = documentDict.key
                        annotation.page = pageDict.key
                        result.append(annotation)
                    }
                }
            }
        }

        return result
    }


    class func parseApi3(string: String) -> [Annotation] {

        var result = [Annotation]()
        let decoder = JSONDecoder()
        let parsedData = try? decoder.decode([[Int: [Annotation]]].self, from: string.data(using: .utf8)!)

        if (parsedData == nil) {
            return result
        }

        for stepDict in parsedData! {
            for pageDict in stepDict {
                for annotation in pageDict.value {
                    annotation.documentId = nil
                    annotation.page = pageDict.key
                    result.append(annotation)
                }
            }
        }

        return result
    }


    class func toPdfAnnotation(_ annotation: Annotation, pageHeight: CGFloat, pdfPage: PDFPage) -> PDFAnnotation {

        // Translating annotation from top-right-origin (web)
        // to bottom-left-origin (PDFKit)

        let rect = ViewUtils.translateDpi(rect: annotation.rect.standardized, oldDpi: 150, newDpi: 72)
        let bounds = CGRect(
                x: rect.origin.x,
                y: pageHeight - rect.origin.y,
                width: rect.width,
                height: -(rect.height)
        )

        let result = PdfAnnotationDrawer.createAnnotation(rect: bounds.standardized,
                                                          page: pdfPage,
                                                          color: PdfAnnotationDrawer.defaultColor)

        AnnotationsUtils.updatePdfMetadata(pdfAnnotation: result, annotation: annotation)

        return result
    }


    class func fromPdfAnnotation(_ pdfAnnotation: PDFAnnotation, pageNumber: Int, pageHeight: CGFloat) -> Annotation {

        let jsonDecoder = JSONDecoder()
        let annotationJsonString = pdfAnnotation.value(forAnnotationKey: .widgetValue) as? String ?? ""
        let result = (try? jsonDecoder.decode(Annotation.self, from: annotationJsonString.data(using: .utf8)!)) ?? Annotation(currentPage: pageNumber)!

        // Translating annotation bottom-left-origin (PDFKit)
        // to from top-right-origin (web)

        let rect = CGRect(
                x: pdfAnnotation.bounds.origin.x,
                y: pageHeight - pdfAnnotation.bounds.origin.y,
                width: pdfAnnotation.bounds.width,
                height: -(pdfAnnotation.bounds.height)
        )

        result.rect = ViewUtils.translateDpi(rect: rect, oldDpi: 72, newDpi: 150)

        return result
    }


    class func updatePdfMetadata(pdfAnnotation: PDFAnnotation, annotation: Annotation) {

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let annotationJson = try! jsonEncoder.encode(annotation)
        let annotationString = String(data: annotationJson, encoding: .utf8)!

        pdfAnnotation.setValue(annotationString, forAnnotationKey: .widgetValue)
    }

}
