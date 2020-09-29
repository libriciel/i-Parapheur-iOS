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


class PdfController: UIViewController, PdfAnnotationEventsDelegate {

    @IBOutlet var pdfView: PDFView!

    let pdfDrawer = PdfAnnotationDrawer()
    let pdfAnnotationGestureRecognizer = PdfAnnotationGestureRecognizer()
    var currentSpinner: UIView?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        setupPdfView(pdfView)
    }

    /**
        Proper scale on rotation.
        Bug defined here : https://stackoverflow.com/a/51106199/9122113
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        pdfView.autoScales = true
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="PdfAnnotationEventsDelegate"> MARK: - PdfAnnotationEventsDelegate


    func onAnnotationMoved(_ annotation: PDFAnnotation?) {
        preconditionFailure("This method must be overridden")
    }


    func onAnnotationSelected(_ annotation: PDFAnnotation?) {
        preconditionFailure("This method must be overridden")
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    static func getBackgroundColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemGray
        }
        else {
            return UIColor.gray
        }
    }


    func showSpinner() {

        let spinnerView = UIView(frame: view.bounds)
        spinnerView.backgroundColor = pdfView.backgroundColor

        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.startAnimating()
        activityIndicatorView.center = spinnerView.center

        DispatchQueue.main.async {
            spinnerView.addSubview(activityIndicatorView)
            self.view.addSubview(spinnerView)
        }

        currentSpinner = spinnerView
    }


    func hideSpinner() {
        DispatchQueue.main.async {
            self.currentSpinner?.removeFromSuperview()
            self.currentSpinner = nil
        }
    }


    func setupPdfView(_ pdfView: PDFView) {
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 3
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = PdfController.getBackgroundColor()

        pdfAnnotationGestureRecognizer.drawingDelegate = pdfDrawer
        pdfAnnotationGestureRecognizer.eventsDelegate = self
        pdfView.addGestureRecognizer(pdfAnnotationGestureRecognizer)
        pdfDrawer.pdfView = pdfView
    }


    func loadPdf(pdfUrl: URL) {
        if let pdfDocument = PDFDocument(url: pdfUrl) {
            pdfView.document = pdfDocument
            setupPdfView(pdfView)
        }
    }


    func isInCreateAnnotationMode() -> Bool {
        return pdfAnnotationGestureRecognizer.isInEditAnnotationMode
    }


    func setCreateAnnotationMode(value: Bool) {
        pdfAnnotationGestureRecognizer.isInEditAnnotationMode = value
    }

}
