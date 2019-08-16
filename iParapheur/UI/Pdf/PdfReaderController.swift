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
import Floaty
import os


class PdfReaderController: PdfController, FolderListDelegate {


    @IBOutlet weak var floatingActionButton: Floaty!
    @IBOutlet weak var documentsButton: UIBarButtonItem!
    @IBOutlet weak var detailsButton: UIBarButtonItem!

    let annotationItem = FloatyItem()
    let rejectItem = FloatyItem()
    let signItem = FloatyItem()
    let visaItem = FloatyItem()

    var restClient: RestClient?
    var currentDesk: Bureau?
    var currentFolder: Dossier?
    var currentWorkflow: Circuit?
    var currentAnnotations: [Annotation]?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View Loaded : PdfReaderController")

        // Prepare Floaty items

        annotationItem.buttonColor = UIColor.gray
        annotationItem.title = "Annoter"
        annotationItem.icon = UIImage(named: "ic_edit_white_24dp")!
        annotationItem.handler = {
            item in
            self.onCreateAnnotationFloatingButtonClicked()
        }

        rejectItem.buttonColor = UIColor.red
        rejectItem.title = "Rejeter"
        rejectItem.icon = UIImage(named: "ic_close_white_24dp")!
        rejectItem.handler = {
            item in
            self.onFolderActionFloatingButtonClicked(action: WorkflowDialogController.ACTION_REJECT)
        }

        signItem.buttonColor = ColorUtils.DarkGreen
        signItem.title = "Signer"
        signItem.icon = UIImage(named: "ic_check_white_18dp")!
        signItem.handler = {
            item in
            self.onFolderActionFloatingButtonClicked(action: WorkflowDialogController.ACTION_SIGNATURE)
        }

        visaItem.buttonColor = ColorUtils.DarkGreen
        visaItem.title = "Signer"
        visaItem.icon = UIImage(named: "ic_check_white_18dp")!
        visaItem.handler = {
            item in
            self.onFolderActionFloatingButtonClicked(action: WorkflowDialogController.ACTION_VISA)
        }

        // UI fine tuning

        documentsButton.isEnabled = false
        detailsButton.isEnabled = false

        // Observers

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDocumentSelected(_:)),
                                               name: DocumentSelectionController.NotifShowDocument,
                                               object: nil)
    }


    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {

//        if (segue.identifier == "dossierDetails"),
//           let destinationController = segue.destination as? RGDossierDetailViewController {
//            destinationController.dossierRef = currentFolder.identifier
//        }
        if (segue.identifier == DocumentSelectionController.SEGUE),
           let destinationController = segue.destination as? DocumentSelectionController,
           let folder = currentFolder {

            let pdfDocuments = folder.documents.filter { ($0.isMainDocument || $0.isPdfVisual) }
            destinationController.documentList = pdfDocuments
        }
        else if (segue.identifier == WorkflowDialogController.SEGUE),
                let destinationController = segue.destination as? WorkflowDialogController,
                let folder = currentFolder {

            destinationController.currentAction = sender as? String
            destinationController.restClient = restClient
            destinationController.signInfoMap = [folder: nil]
            destinationController.currentBureau = currentDesk?.identifier
        }
        else {
            super.prepare(for: segue, sender: sender)
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI listeners"> MARK: - UI listeners


    private func onCreateAnnotationFloatingButtonClicked() {
        setCreateAnnotationMode(value: true)
    }


    private func onFolderActionFloatingButtonClicked(action: String) {
        performSegue(withIdentifier: WorkflowDialogController.SEGUE, sender: action)
    }


    @objc func onDocumentSelected(_ notification: NSNotification) {

        if let documentIndex = notification.object as? NSNumber,
           documentIndex.intValue < (currentFolder?.documents.count ?? 0),
           documentIndex.intValue >= 0 {

            downloadPdf(documentIndex: documentIndex.intValue)
        }
    }


    // </editor-fold desc="UI listeners">


    // <editor-fold desc="FolderListDelegate"> MARK: - FolderListDelegate


    func onFolderSelected(_ folder: Dossier, desk: Bureau, restClient: RestClient) {

        self.restClient = restClient
        self.currentFolder = folder
        self.currentDesk = desk

        downloadFolderMetadata()
        downloadPdf(documentIndex: 0)
    }


    // </editor-fold desc="FolderListDelegate">


    // <editor-fold desc="PdfAnnotationEventsDelegate"> MARK: - PdfAnnotationEventsDelegate


    override func onAnnotationSelected(_ annotation: PDFAnnotation?) {
        os_log("Annotation selected !! %@", annotation ?? "(nil)")
    }


    override func onAnnotationMoved(_ annotation: PDFAnnotation?) {

        guard let folderId = currentFolder?.identifier,
              let currentAnnotation = annotation,
              let currentPage = currentAnnotation.page,
              let pageNumber = pdfView.document?.index(for: currentPage) else { return }

        let fixedAnnotation = PdfReaderController.translateToAnnotation(currentAnnotation,
                                                                        pageNumber: pageNumber,
                                                                        pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

        restClient?.updateAnnotation(fixedAnnotation,
                                     folderId: folderId,
                                     responseCallback: {
                                         os_log("updateAnnotation success")
                                     },
                                     errorCallback: {
                                         (error: Error) in
                                         ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError),
                                                            title: "Erreur à la sauvegarde de l'annotation")
                                     }
        )
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    class func translateToPdfAnnotation(_ annotation: Annotation, pageHeight: CGFloat) -> PDFAnnotation {

        // Translating annotation from top-right-origin (web)
        // to bottom-left-origin (PDFKit)

        let rect = ViewUtils.translateDpi(rect: annotation.rect, oldDpi: 150, newDpi: 72)
        let bounds = CGRect(
                x: rect.origin.x,
                y: pageHeight - rect.origin.y,
                width: rect.width,
                height: -(rect.height)
        )

        let result = PDFAnnotation(bounds: bounds.standardized,
                                   forType: .square,
                                   withProperties: nil)

        // Metadata

//        let annotationColor: UIColor = annotation.isEditable ? ColorUtils.DarkBlue : UIColor.darkGray
//
//        result.setValue(annotationColor.withAlphaComponent(0.6), forAnnotationKey: .interiorColor)
//        result.setValue(annotationColor.withAlphaComponent(0.1), forAnnotationKey: .color)
        result.setValue(PDFAnnotationHighlightingMode.none, forAnnotationKey: .highlightingMode)
        result.setValue(annotation.author, forAnnotationKey: .name)
        result.setValue(annotation.text, forAnnotationKey: .textLabel)
        result.setValue(annotation.date, forAnnotationKey: .date)
        result.setValue(annotation.identifier, forAnnotationKey: .parent)
        result.setValue(annotation.isEditable ? PdfAnnotationDrawer.FLAG_LOCKED : PdfAnnotationDrawer.FLAG_NORMAL, forAnnotationKey: .flags)

        // View

        let border = PDFBorder()
        border.lineWidth = 2.0
        result.border = border
//        result.color = annotationColor.withAlphaComponent(0.6)
//        result.interiorColor = annotationColor.withAlphaComponent(0.1)

        return result
    }


    class func translateToAnnotation(_ pdfAnnotation: PDFAnnotation, pageNumber: Int, pageHeight: CGFloat) -> Annotation {

        let result = Annotation(currentPage: pageNumber)!

        // Translating annotation bottom-left-origin (PDFKit)
        // to from top-right-origin (web)

        let rect = CGRect(
                x: pdfAnnotation.bounds.origin.x,
                y: pageHeight - pdfAnnotation.bounds.origin.y,
                width: pdfAnnotation.bounds.width,
                height: -(pdfAnnotation.bounds.height)
        )

        result.rect = ViewUtils.translateDpi(rect: rect, oldDpi: 72, newDpi: 150)

        // Metadata

        result.author = pdfAnnotation.value(forAnnotationKey: .name) as? String ?? ""
        result.text = pdfAnnotation.value(forAnnotationKey: .textLabel) as? String ?? ""
        result.date = pdfAnnotation.value(forAnnotationKey: .date) as? Date ?? Date()
        result.identifier = pdfAnnotation.value(forAnnotationKey: .parent) as? String ?? "_new"

        return result
    }


    private func downloadFolderMetadata() {

        guard let folder = currentFolder,
              let desk = currentDesk,
              let restClient = self.restClient else { return }

        restClient.getDossier(dossier: folder.identifier,
                              bureau: desk.identifier,
                              onResponse: {
                                  (folder: Dossier) in
                                  self.currentFolder = folder
                                  self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                              },
                              onError: {
                                  (error: Error) in
                                  ViewUtils.logError(message: error.localizedDescription as NSString,
                                                     title: "Impossible de télécharger le dossier")
                              })

        restClient.getCircuit(dossier: folder.identifier,
                              onResponse: {
                                  (workflow: Circuit) in
                                  self.currentWorkflow = workflow
                                  self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                              },
                              onError: {
                                  (error: Error) in
                                  ViewUtils.logError(message: error.localizedDescription as NSString,
                                                     title: "Impossible de télécharger le dossier")
                              })

        restClient.getAnnotations(dossier: folder.identifier,
                                  onResponse: {
                                      (annotations: [Annotation]) in
                                      self.currentAnnotations = annotations
                                      self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                                  },
                                  onError: {
                                      (error: Error) in
                                      ViewUtils.logError(message: error.localizedDescription as NSString,
                                                         title: "Impossible de télécharger le dossier")
                                  })
    }


    private func checkIfEverythingIsSetBeforeDisplayingThePdf() {

        if (currentFolder?.documents.count ?? 0) > 0,
           currentWorkflow != nil,
           currentAnnotations != nil,
           let folder = currentFolder {

            detailsButton.isEnabled = true

            let pdfDocuments = folder.documents.filter { ($0.isMainDocument || $0.isPdfVisual) }
            if (pdfDocuments.count > 1) {
                documentsButton.isEnabled = true
            }

            downloadPdf(documentIndex: 0)
        }
    }


    private func downloadPdf(documentIndex: Int) {

        guard let folder = currentFolder,
              let restClient = self.restClient else { return }

        let pdfDocuments = folder.documents.filter { ($0.isMainDocument || $0.isPdfVisual) }

        guard (documentIndex < pdfDocuments.count),
              (documentIndex >= 0) else { return }

        let document = pdfDocuments[documentIndex]

        // Prepare

        var localFileUrl: URL?
        do {
            localFileUrl = try getLocalFileUrl(dossierId: folder.identifier, documentName: document.identifier)
        } catch {
            ViewUtils.logError(message: "Impossible d'écrire sur le disque",
                               title: "Téléchargement échoué")
        }

        guard let localFileDownloaded = localFileUrl else { return }

        if (FileManager.default.fileExists(atPath: localFileDownloaded.absoluteString)) {
            loadPdf(documentPath: localFileDownloaded)
            return
        }

        // Download

        restClient.downloadFile(document: document,
                                path: localFileDownloaded,
                                onResponse: {
                                    (response: String) in

                                    self.loadPdf(documentPath: localFileDownloaded)
                                },
                                onError: {
                                    (error: Error) in

                                    self.pdfView.document = nil
                                    self.refreshFloatingActionButton(documentLoaded: nil)

                                    ViewUtils.logError(message: error.localizedDescription as NSString,
                                                       title: "Téléchargement échoué")
                                }
        )
    }


    private func loadPdf(documentPath: URL) {
        if let pdfDocument = PDFDocument(url: documentPath) {

            for annotation in self.currentAnnotations ?? [] {
                guard let pdfPage = pdfDocument.page(at: annotation.page) else { return }
                let pageHeight = pdfPage.bounds(for: pdfView.displayBox).height
                let pdfAnnotation = PdfReaderController.translateToPdfAnnotation(annotation, pageHeight: pageHeight)

                pdfPage.addAnnotation(pdfAnnotation)
            }

            self.pdfView.document = pdfDocument
            self.refreshFloatingActionButton(documentLoaded: pdfDocument)
        }
        else {
            try? FileManager.default.removeItem(at: documentPath)
            ViewUtils.logError(message: "Veuillez réessayer", title: "Erreur au chargement du fichier")
        }
    }


    private func refreshFloatingActionButton(documentLoaded: PDFDocument?) {

        floatingActionButton.removeItem(item: annotationItem)
        floatingActionButton.removeItem(item: visaItem)
        floatingActionButton.removeItem(item: signItem)
        floatingActionButton.removeItem(item: rejectItem)

        if (currentFolder != nil) {

            let positiveAction = Dossier.getPositiveAction(folders: [currentFolder!])
            let negativeAction = Dossier.getNegativeAction(folders: [currentFolder!])

            if (positiveAction == "SIGNATURE") { floatingActionButton.addItem(item: signItem) }
            if (positiveAction == "VISA") { floatingActionButton.addItem(item: visaItem) }
            if (negativeAction == "REJET") { floatingActionButton.addItem(item: rejectItem) }
            floatingActionButton.addItem(item: annotationItem)
        }

        if ((documentLoaded != nil) && floatingActionButton.isHidden) {
            floatingActionButton.isHidden = false
        }

        if ((documentLoaded == nil) && !floatingActionButton.isHidden) {
            self.floatingActionButton.isHidden = true
        }
    }


    private func getLocalFileUrl(dossierId: String,
                                 documentName: String) throws -> URL {

        // Source folder

        var documentsDirectoryUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("dossiers", isDirectory: true)
                .appendingPathComponent(dossierId, isDirectory: true)

        try FileManager.default.createDirectory(at: documentsDirectoryUrl, withIntermediateDirectories: true)

        // File name

        var fileName = documentName.replacingOccurrences(of: " ", with: "_")
        fileName = String(format: "%@.bin", fileName)

        documentsDirectoryUrl = documentsDirectoryUrl.appendingPathComponent(fileName)
        return documentsDirectoryUrl
    }

}
