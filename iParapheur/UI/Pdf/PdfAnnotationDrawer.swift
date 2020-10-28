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
import os

/**
    Largely taken from this tutorial :
    https://medium.com/@artempoluektov/ios-pdfkit-ink-annotations-tutorial-4ba19b474dce
    The tutorial sets how read pencil drawing can be done with Bézier curves.
    I basically replace those with rectangles...
    ... But we might want to check those Bézier curves for a hand-written signature, some time.
 */
class PdfAnnotationDrawer: PdfAnnotationGestureRecognizerDelegate {


    // PDF 1.7 Standards
    static let flagNormal = 0
    static let flagLocked = 8

    static var defaultColor = ColorUtils.darkBlue

    weak var pdfView: PDFView!

    private var currentAnnotation: PDFAnnotation?
    private var currentRect: CGRect?
    private var currentPage: PDFPage?
    private var currentInsideHit: CGPoint?


    // <editor-fold desc="DrawingGestureRecognizerDelegate"> MARK: - DrawingGestureRecognizerDelegate


    func pressBeganInEditMode(pdfAnnotation: PDFAnnotation, insideHit: CGPoint, forceRedraw: Bool) {

        currentPage = pdfAnnotation.page
        currentAnnotation = pdfAnnotation
        currentAnnotation?.setValue(PDFAnnotationHighlightingMode.outline, forAnnotationKey: .highlightingMode)
        currentInsideHit = insideHit

        currentRect = CGRect(origin: CGPoint(x: currentAnnotation!.bounds.origin.x,
                                             y: currentAnnotation!.bounds.origin.y + currentAnnotation!.bounds.height),
                             size: CGSize(width: currentAnnotation!.bounds.width,
                                          height: -currentAnnotation!.bounds.height))

        if forceRedraw {
            drawAnnotation(onPage: currentPage!)
        }
    }


    func pressBeganInCreateMode(_ location: CGPoint) {

        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)

        // Actual logic

        currentRect = CGRect(origin: convertedPoint, size: CGSize(width: 0, height: 0))
        currentAnnotation = PdfAnnotationDrawer.createAnnotation(rect: currentRect!, page: page, color: PdfAnnotationDrawer.defaultColor)
        currentInsideHit = nil
    }


    func pressMoved(_ location: CGPoint, _ isLongPress: Bool) {

        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)

        // Actual logic

        if (isLongPress) {
            guard let newRect = computeMovedRectangle(location: convertedPoint, page: page) else { return }
            currentRect = newRect
        }
        else {
            guard let newSize = computeResizedRectangleSize(location: convertedPoint, page: page) else { return }
            currentRect?.size = newSize
        }

        drawAnnotation(onPage: page)
    }


    func pressEnded(_ location: CGPoint, _ isLongPress: Bool) {

        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)

        // Actual logic

        if isLongPress {
            if let newRect = computeMovedRectangle(location: convertedPoint, page: page) {
                currentRect = newRect
            }
        }
        else {
            if let newSize = computeResizedRectangleSize(location: convertedPoint, page: page) {
                currentRect?.size = newSize
            }
        }

        currentAnnotation?.setValue(PDFAnnotationHighlightingMode.none, forAnnotationKey: .highlightingMode)

        drawAnnotation(onPage: page)
        currentAnnotation = nil
        currentInsideHit = nil
        currentRect = nil
    }


    func targetedAnnotation(_ location: CGPoint) -> (PDFAnnotation, CGPoint)? {

        guard let page = pdfView.page(for: location, nearest: true) else { return nil }
        let convertedPoint = pdfView.convert(location, to: page)

        // Actual logic

        guard let targetAnnotation = page.annotation(at: convertedPoint) else { return nil }

        let insideHit = CGPoint(x: convertedPoint.x - targetAnnotation.bounds.origin.x,
                                y: convertedPoint.y - targetAnnotation.bounds.origin.y)

        return (targetAnnotation, insideHit)
    }


    func getCurrentAnnotation() -> PDFAnnotation? {
        return currentAnnotation
    }


    // </editor-fold desc="DrawingGestureRecognizerDelegate">


    class func createAnnotation(rect: CGRect, page: PDFPage, color: UIColor) -> PDFAnnotation {

        let border = PDFBorder()
        border.lineWidth = 2.0

        let annotation = PDFAnnotation(bounds: rect,
                                       forType: .square,
                                       withProperties: nil)

        // Setting view's attributes

        annotation.setValue(PDFAnnotationHighlightingMode.none, forAnnotationKey: .highlightingMode)
        annotation.border = border
        annotation.color = color.withAlphaComponent(0.6)

        if (PDFAnnotation.instancesRespond(to: #selector(setter: PDFAnnotation.interiorColor))) { // iOS 11 bugfix
            annotation.interiorColor = color.withAlphaComponent(0.1)
        }

        return annotation
    }


    private func computeResizedRectangleSize(location: CGPoint, page: PDFPage) -> CGSize? {

        guard let currentRect = currentRect else { return nil }
        let pageBounds = page.bounds(for: pdfView.displayBox)

        // Bounds into the PDF page size

        var xWithBoundaries = location.x
        xWithBoundaries = max(pageBounds.origin.x, xWithBoundaries)
        xWithBoundaries = min(pageBounds.origin.x + pageBounds.size.width, xWithBoundaries)

        var yWithBoundaries = location.y
        yWithBoundaries = max(pageBounds.origin.y, yWithBoundaries)
        yWithBoundaries = min(pageBounds.origin.y + pageBounds.size.height, yWithBoundaries)

        // Setting calculated values

        let width = xWithBoundaries - currentRect.origin.x
        let height = yWithBoundaries - currentRect.origin.y

        return CGSize(width: width, height: height)
    }


    private func computeMovedRectangle(location: CGPoint, page: PDFPage) -> CGRect? {

        guard let insideHit = currentInsideHit,
              let rect = currentRect else { return nil }

        let pageBounds = page.bounds(for: pdfView.displayBox)

        // Bounds into the PDF page size

        var xWithBoundaries = location.x - insideHit.x
        xWithBoundaries = max(pageBounds.origin.x, xWithBoundaries)
        xWithBoundaries = min(pageBounds.origin.x + pageBounds.size.width - rect.width, xWithBoundaries)

        var yWithBoundaries = location.y - insideHit.y
        yWithBoundaries = max(pageBounds.origin.y, yWithBoundaries)
        yWithBoundaries = min(pageBounds.origin.y + pageBounds.size.height - rect.height, yWithBoundaries)

        // Setting calculated values

        return CGRect(x: xWithBoundaries, y: yWithBoundaries, width: rect.width, height: rect.height)
    }

    /**
        Due to a nasty bug (https://stackoverflow.com/a/46911395/9122113),
        we have to remove and replace the annotation to render it properly.
     */
    private func drawAnnotation(onPage: PDFPage) {

        guard let rect = currentRect,
              let annotation = currentAnnotation else { return }

        annotation.page?.removeAnnotation(annotation)
        annotation.bounds = rect.standardized

        let highlightingMode = (annotation.value(forAnnotationKey: .highlightingMode) as? PDFAnnotationHighlightingMode) ?? .none
        if (PDFAnnotation.instancesRespond(to: #selector(setter: PDFAnnotation.interiorColor))) { // iOS 11 bugfix
            annotation.interiorColor = annotation.color.withAlphaComponent((highlightingMode == .outline) ? 0.4 : 0.1)
        }

        onPage.addAnnotation(annotation)
    }

}