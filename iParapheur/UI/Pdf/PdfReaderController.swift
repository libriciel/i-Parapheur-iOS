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


class PdfReaderController: PdfController, FolderListDelegate, AnnotationDetailsControllerDelegate {


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
    var currentDocument: Document?
    var currentWorkflow: Circuit?
    var currentAnnotations: [Annotation]?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View Loaded : PdfReaderController")

        // Bugfix on keyboard showing https://github.com/kciter/Floaty/issues/79

        floatingActionButton.sticky = true

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


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

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
        else if (segue.identifier == AnnotationDetailsController.SEGUE),
                let destinationController = segue.destination as? AnnotationDetailsController,
                let annotation = sender as? Annotation {

            destinationController.currentAnnotation = annotation
            destinationController.currentFolder = currentFolder
            destinationController.currentDocument = currentDocument
            destinationController.restClient = restClient
            destinationController.delegate = self
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


    // <editor-fold desc="AnnotationDetailsControllerDelegate"> MARK: - AnnotationDetailsControllerDelegate


    func onAnnotationChanged(annotation: Annotation) {

        guard let currentPage = pdfView.document?.page(at: annotation.page) else { return }

        for pdfAnnotation in currentPage.annotations {

            let testAnnotation = PdfReaderController.translateToAnnotation(pdfAnnotation,
                                                                           pageNumber: annotation.page,
                                                                           pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

            if (testAnnotation.identifier == annotation.identifier) {
                PdfReaderController.updatePdfAnnotationMetadata(pdfAnnotation: pdfAnnotation, annotation: annotation)
            }
        }
    }


    func onAnnotationDeleted(annotation: Annotation) {
        guard let annotation = self.pdfDrawer.getCurrentAnnotation() else { return }
        annotation.page?.removeAnnotation(annotation)
    }


    // </editor-fold desc="AnnotationDetailsControllerDelegate">


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


    override func onAnnotationSelected(_ pdfAnnotation: PDFAnnotation?) {

        guard let currentPdfAnnotation = pdfAnnotation,
              let currentPage = currentPdfAnnotation.page,
              let pageNumber = pdfView.document?.index(for: currentPage) else { return }

        let annotation = PdfReaderController.translateToAnnotation(currentPdfAnnotation,
                                                                   pageNumber: pageNumber,
                                                                   pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

        performSegue(withIdentifier: AnnotationDetailsController.SEGUE, sender: annotation)
    }


    override func onAnnotationMoved(_ annotation: PDFAnnotation?) {

        guard let folderId = currentFolder?.identifier,
              let currentAnnotation = annotation,
              let currentPage = currentAnnotation.page,
              let documentId = currentDocument?.identifier,
              let pageNumber = pdfView.document?.index(for: currentPage) else {
            return
        }


        let fixedAnnotation = PdfReaderController.translateToAnnotation(currentAnnotation,
                                                                        pageNumber: pageNumber,
                                                                        pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

        if (fixedAnnotation.identifier == "_new") {
            restClient?.createAnnotation(fixedAnnotation,
                                         folderId: folderId,
                                         documentId: documentId,
                                         responseCallback: {
                                             (newId: String) in

                                             os_log("createAnnotation success id:%@", newId)
                                             fixedAnnotation.identifier = newId
                                             fixedAnnotation.author = "(Utilisateur courant)"
                                             PdfReaderController.updatePdfAnnotationMetadata(pdfAnnotation: currentAnnotation, annotation: fixedAnnotation)
                                             self.performSegue(withIdentifier: AnnotationDetailsController.SEGUE, sender: fixedAnnotation)
                                         },
                                         errorCallback: {
                                             (error: Error) in

                                             ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError),
                                                                title: "Erreur à la sauvegarde de l'annotation")
                                         })
        }
        else {
            restClient?.updateAnnotation(fixedAnnotation,
                                         folderId: folderId,
                                         documentId: documentId,
                                         responseCallback: {
                                             os_log("updateAnnotation success")
                                         },
                                         errorCallback: {
                                             (error: Error) in
                                             ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError),
                                                                title: "Erreur à la sauvegarde de l'annotation")
                                         })
        }
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    class func translateToPdfAnnotation(_ annotation: Annotation, pageHeight: CGFloat, pdfPage: PDFPage) -> PDFAnnotation {

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
                                                          color: PdfAnnotationDrawer.DEFAULT_COLOR)

        PdfReaderController.updatePdfAnnotationMetadata(pdfAnnotation: result, annotation: annotation)

        return result
    }


    class func updatePdfAnnotationMetadata(pdfAnnotation: PDFAnnotation, annotation: Annotation) {

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let annotationJson = try! jsonEncoder.encode(annotation)
        let annotationString = String(data: annotationJson, encoding: .utf8)!

        pdfAnnotation.setValue(annotationString, forAnnotationKey: .widgetValue)
    }


    class func translateToAnnotation(_ pdfAnnotation: PDFAnnotation, pageNumber: Int, pageHeight: CGFloat) -> Annotation {

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
        currentDocument = document

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
                let pdfAnnotation = PdfReaderController.translateToPdfAnnotation(annotation, pageHeight: pageHeight, pdfPage: pdfPage)

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
            floatingActionButton.isHidden = true
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
