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
import Floaty
import SwiftMessages
import os


class PdfReaderController: PdfController, FolderListDelegate, AnnotationDetailsControllerDelegate {


    static let preferencesKeyAnnotationInfosAlreadySeen = "annotationInfosAlreadySeen"
    static let preferencesKeyAnnotationEditModeInfosAlreadySeen = "annotationEditModeInfosAlreadySeen"

    @IBOutlet weak var floatingActionButton: Floaty!
    @IBOutlet weak var documentsButton: UIBarButtonItem!
    @IBOutlet weak var detailsButton: UIBarButtonItem!

    let annotationItem = FloatyItem()
    let rejectItem = FloatyItem()
    let signItem = FloatyItem()
    let visaItem = FloatyItem()
    let paperSignItem = FloatyItem()

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
        annotationItem.handler = { item in
            self.onCreateAnnotationFloatingButtonClicked()
        }

        rejectItem.buttonColor = UIColor.red
        rejectItem.title = Action.prettyPrint(.reject)
        rejectItem.icon = UIImage(named: "ic_close_white_24dp")!
        rejectItem.handler = { item in
            self.onFolderActionFloatingButtonClicked(action: .reject)
        }

        signItem.buttonColor = ColorUtils.darkGreen
        signItem.title = Action.prettyPrint(.sign)
        signItem.icon = UIImage(named: "ic_check_white_18dp")!
        signItem.handler = { item in
            self.onFolderActionFloatingButtonClicked(action: .sign)
        }

        visaItem.buttonColor = ColorUtils.darkGreen
        visaItem.title = Action.prettyPrint(.visa)
        visaItem.icon = UIImage(named: "ic_check_white_18dp")!
        visaItem.handler = { item in
            self.onFolderActionFloatingButtonClicked(action: .visa)
        }

        paperSignItem.buttonColor = UIColor.gray
        paperSignItem.title = "Transformer en signature papier"
        paperSignItem.icon = UIImage(named: "outline_description_white_24dp")!
        paperSignItem.handler = { item in
            self.onPaperSignFloatingButtonClicked()
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

        if (segue.identifier == FolderDetailsController.segue),
           let destinationController = segue.destination as? FolderDetailsController {

            destinationController.currentFolder = currentFolder
            destinationController.currentWorkflow = currentWorkflow
        }
        else if (segue.identifier == DocumentSelectionController.segue),
                let destinationController = segue.destination as? DocumentSelectionController,
                let folder = currentFolder {

            let pdfDocuments = folder.documents.filter { ($0.isMainDocument || $0.isPdfVisual) }
            destinationController.documentList = pdfDocuments
        }
        else if (segue.identifier == WorkflowDialogController.segue),
                let destinationController = segue.destination as? WorkflowDialogController,
                let action = sender as? Action,
                let folder = currentFolder {

            // Computing action before, to manage paper signature
            let actionToPerform = ActionToPerform(folder: folder, action: action)

            destinationController.currentAction = actionToPerform.action
            destinationController.restClient = restClient
            destinationController.actionsToPerform = [actionToPerform]
            destinationController.currentDeskId = currentDesk?.identifier
        }
        else if (segue.identifier == AnnotationDetailsController.segue),
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

        let preferences = UserDefaults.standard
        let alreadySeen = preferences.bool(forKey: PdfReaderController.preferencesKeyAnnotationEditModeInfosAlreadySeen)
        preferences.set(true, forKey: PdfReaderController.preferencesKeyAnnotationEditModeInfosAlreadySeen)

        if (!alreadySeen) {
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 12)

            ViewUtils.logMessage(title: "Mode annotation",
                                 subtitle: """
                                           - Créer : Glissez votre doigt sur une zone vide
                                           - Redimmensionner : Glissez le coin bas-droit de l'annotation
                                           - Déplacer : Pressez longuement et glissez l'annotation 
                                           """,
                                 messageType: .info,
                                 config: config)
        }

        setCreateAnnotationMode(value: true)
    }


    private func onFolderActionFloatingButtonClicked(action: Action) {
        performSegue(withIdentifier: WorkflowDialogController.segue, sender: action)
    }


    private func onPaperSignFloatingButtonClicked() {

        guard let currentRestClient = self.restClient,
              let folder = currentFolder,
              let desk = currentDesk else { return }

        currentRestClient.switchToPaperSignature(folder: folder,
                                                 desk: desk,
                                                 responseCallback: {
                                                     self.currentFolder?.isSignPapier = true
                                                     self.refreshFloatingActionButton(documentLoaded: self.pdfView.document)
                                                 },
                                                 errorCallback: { error in
                                                     ViewUtils.logError(message: StringsUtils.getMessage(error: error),
                                                                        title: "Erreur à la conversion en signature papier")
                                                 })

    }


    @objc func onDocumentSelected(_ notification: NSNotification) {

        if let documentIndex = notification.object as? NSNumber,
           documentIndex.intValue < (currentFolder?.documents.count ?? 0),
           documentIndex.intValue >= 0 {

            downloadPdf(documentIndex: documentIndex.intValue)
        }

        showSpinner()
    }


    // </editor-fold desc="UI listeners">


    // <editor-fold desc="AnnotationDetailsControllerDelegate"> MARK: - AnnotationDetailsControllerDelegate


    func onAnnotationChanged(annotation: Annotation) {
        guard let currentPage = pdfView.document?.page(at: annotation.page) else { return }

        for pdfAnnotation in currentPage.annotations {

            let testAnnotation = AnnotationsUtils.fromPdfAnnotation(pdfAnnotation,
                                                                    pageNumber: annotation.page,
                                                                    pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

            if (testAnnotation.identifier == annotation.identifier) {
                AnnotationsUtils.updatePdfMetadata(pdfAnnotation: pdfAnnotation, annotation: annotation)
            }
        }
    }


    func onAnnotationPopupDismissed() {
        checkFirstAnnotation()
    }


    func onAnnotationDeleted(annotation: Annotation) {
        guard let annotation = pdfDrawer.getCurrentAnnotation() else { return }
        annotation.page?.removeAnnotation(annotation)
    }


    // </editor-fold desc="AnnotationDetailsControllerDelegate">


    // <editor-fold desc="FolderListDelegate"> MARK: - FolderListDelegate


    func onFolderSelected(_ folder: Dossier, desk: Bureau, restClient: RestClient) {

        showSpinner()
        documentsButton.isEnabled = false
        detailsButton.isEnabled = false

        self.restClient = restClient
        self.currentFolder = folder
        self.currentDesk = desk

        downloadFolderMetadata()
        downloadPdf(documentIndex: 0)
    }


    func onFolderMultipleSelectionStarted() {
        floatingActionButton.isHidden = true
    }


    func onFolderMultipleSelectionEnded() {
        if pdfView.document != nil {
            floatingActionButton.isHidden = false
        }
    }


    // </editor-fold desc="FolderListDelegate">


    // <editor-fold desc="PdfAnnotationEventsDelegate"> MARK: - PdfAnnotationEventsDelegate


    override func onAnnotationSelected(_ pdfAnnotation: PDFAnnotation?) {

        guard let currentPdfAnnotation = pdfAnnotation,
              let currentPage = currentPdfAnnotation.page,
              let pageNumber = pdfView.document?.index(for: currentPage) else { return }

        let annotation = AnnotationsUtils.fromPdfAnnotation(currentPdfAnnotation,
                                                            pageNumber: pageNumber,
                                                            pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

        performSegue(withIdentifier: AnnotationDetailsController.segue, sender: annotation)
    }


    override func onAnnotationMoved(_ annotation: PDFAnnotation?) {

        guard let folderId = currentFolder?.identifier,
              let currentAnnotation = annotation,
              let currentPage = currentAnnotation.page,
              let documentId = currentDocument?.identifier,
              let pageNumber = pdfView.document?.index(for: currentPage) else {
            return
        }

        let fixedAnnotation = AnnotationsUtils.fromPdfAnnotation(currentAnnotation,
                                                                 pageNumber: pageNumber,
                                                                 pageHeight: currentPage.bounds(for: pdfView.displayBox).height)

        if (fixedAnnotation.identifier == "_new") {
            restClient?.createAnnotation(fixedAnnotation,
                                         folderId: folderId,
                                         documentId: documentId,
                                         responseCallback:
                                         { (newId: String) in

                                             os_log("createAnnotation success id:%@", newId)
                                             fixedAnnotation.identifier = newId
                                             fixedAnnotation.author = "(Utilisateur courant)"
                                             AnnotationsUtils.updatePdfMetadata(pdfAnnotation: currentAnnotation, annotation: fixedAnnotation)
                                             self.performSegue(withIdentifier: AnnotationDetailsController.segue, sender: fixedAnnotation)
                                         },
                                         errorCallback: { (error: Error) in

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
                                         errorCallback: { (error: Error) in
                                             ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError),
                                                                title: "Erreur à la sauvegarde de l'annotation")
                                         })
        }
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    private func downloadFolderMetadata() {

        guard let folder = currentFolder,
              let desk = currentDesk,
              let restClient = self.restClient else { return }

        restClient.getFolder(folder: folder.identifier,
                             desk: desk.identifier,
                             onResponse: { (folder: Dossier) in
                                 self.currentFolder = folder
                                 self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                             },
                             onError: { (error: Error) in
                                 ViewUtils.logError(message: error.localizedDescription as NSString,
                                                    title: "Impossible de télécharger le dossier")
                             })

        restClient.getWorkflow(folder: folder.identifier,
                               onResponse: { (workflow: Circuit) in
                                   self.currentWorkflow = workflow
                                   self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                               },
                               onError: { (error: Error) in
                                   ViewUtils.logError(message: error.localizedDescription as NSString,
                                                      title: "Impossible de télécharger le dossier")
                               })

        restClient.getAnnotations(folder: folder.identifier,
                                  onResponse: { (annotations: [Annotation]) in
                                      self.currentAnnotations = annotations
                                      self.checkIfEverythingIsSetBeforeDisplayingThePdf()
                                  },
                                  onError: { (error: Error) in
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
            if pdfDocuments.count > 1 {
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

        guard let localFileUrl = try? Dossier.getLocalFileUrl(dossierId: folder.identifier,
                                                              documentName: document.identifier) else {
            ViewUtils.logError(message: "Impossible d'écrire sur le disque",
                               title: "Téléchargement échoué")
            return
        }

        if FileManager.default.fileExists(atPath: localFileUrl.absoluteString) {
            loadPdf(documentPath: localFileUrl)
            return
        }

        // Download

        restClient.downloadFile(document: document,
                                path: localFileUrl,
                                onResponse:
                                { (response: String) in
                                    self.loadPdf(documentPath: localFileUrl)
                                },
                                onError: { (error: Error) in

                                    self.pdfView.document = nil
                                    self.refreshFloatingActionButton(documentLoaded: nil)

                                    ViewUtils.logError(message: error.localizedDescription as NSString,
                                                       title: "Téléchargement échoué")
                                }
        )
    }


    private func loadPdf(documentPath: URL) {

        guard let pdfDocument = PDFDocument(url: documentPath),
              let document = currentDocument,
              let folder = currentFolder else {

            try? FileManager.default.removeItem(at: documentPath)
            ViewUtils.logError(message: "Veuillez réessayer", title: "Erreur au chargement du fichier")
            return
        }

        var annotations: [Annotation] = (currentAnnotations ?? [])
        annotations = annotations.filter({ $0.documentId == document.identifier })

        for annotation in annotations {

            guard let pdfPage = pdfDocument.page(at: annotation.page) else { return }
            let pageHeight = pdfPage.bounds(for: pdfView.displayBox).height
            let pdfAnnotation = AnnotationsUtils.toPdfAnnotation(annotation, pageHeight: pageHeight, pdfPage: pdfPage)

            pdfPage.addAnnotation(pdfAnnotation)
        }

        if (annotations.count > 0) {
            checkFirstAnnotation()
        }

        pdfView.document = pdfDocument
        setupPdfView(pdfView)

        refreshFloatingActionButton(documentLoaded: pdfDocument)

        hideSpinner()
        documentsButton.isEnabled = folder.documents.filter({ $0.isMainDocument || $0.isPdfVisual }).count > 1
        detailsButton.isEnabled = true
    }


    private func refreshFloatingActionButton(documentLoaded: PDFDocument?) {

        floatingActionButton.removeItem(item: annotationItem)
        floatingActionButton.removeItem(item: visaItem)
        floatingActionButton.removeItem(item: signItem)
        floatingActionButton.removeItem(item: rejectItem)
        floatingActionButton.removeItem(item: paperSignItem)

        guard let folder = currentFolder else { return }

        let positiveAction = Dossier.getPositiveAction(folders: [folder])
        let negativeAction = Dossier.getNegativeAction(folders: [folder])
        let digitalSignatureMandatory = currentWorkflow?.isDigitalSignatureMandatory ?? true

        if positiveAction == .sign { floatingActionButton.addItem(item: signItem) }
        if positiveAction == .visa { floatingActionButton.addItem(item: visaItem) }
        if negativeAction == .reject { floatingActionButton.addItem(item: rejectItem) }
        if positiveAction == .sign && (!digitalSignatureMandatory) && !folder.isSignPapier { floatingActionButton.addItem(item: paperSignItem) }
        if !ViewUtils.isConnectedToDemoAccount() { floatingActionButton.addItem(item: annotationItem) }

        if (documentLoaded != nil) && floatingActionButton.isHidden { floatingActionButton.isHidden = false }
        if (documentLoaded == nil) && !floatingActionButton.isHidden { floatingActionButton.isHidden = true }
    }


    private func checkFirstAnnotation() {

        let preferences = UserDefaults.standard
        let alreadySeen = preferences.bool(forKey: PdfReaderController.preferencesKeyAnnotationInfosAlreadySeen)
        preferences.set(true, forKey: PdfReaderController.preferencesKeyAnnotationInfosAlreadySeen)

        if (!alreadySeen) {
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 12)

            ViewUtils.logMessage(title: "Une annotation est visible sur ce document",
                                 subtitle: """
                                           - Voir ou modifier son contenu : Double-tapez dessus
                                           - La déplacer : Passez en mode annotation avec le bouton +
                                           """,
                                 messageType: .info,
                                 config: config)
        }
    }

}
