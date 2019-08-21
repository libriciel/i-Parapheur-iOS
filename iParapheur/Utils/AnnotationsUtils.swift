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
