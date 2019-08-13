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
import os


class PdfReaderController: PdfController, FolderListDelegate {


    var restClient: RestClient?
    var currentDesk: Bureau?
    var currentFolder: Dossier?
    var currentWorkflow: Circuit?


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View Loaded : PdfReaderController")
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI listeners"> MARK: - UI listeners


    @IBAction func onDocumentButtonClicked(_ sender: Any) {
        downloadPdf(documentIndex: 0)
    }


    @IBAction func onDetailButtonClicked(_ sender: Any) {
        setCreateAnnotationMode(value: !isInCreateAnnotationMode())
    }


    @IBAction func onActionButtonClicked(_ sender: Any) {

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
        os_log("Annotation moved !! %@", annotation ?? "(nil)")
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    private func downloadFolderMetadata() {

        guard let folder = currentFolder,
              let desk = currentDesk,
              let restClient = self.restClient else { return }

        restClient.getDossier(dossier: folder.identifier,
                              bureau: desk.identifier,
                              onResponse: {
                                  (folder: Dossier) in
                                  self.currentFolder = folder
                                  self.downloadPdf(documentIndex: 0)
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
                              },
                              onError: {
                                  (error: Error) in
                                  ViewUtils.logError(message: error.localizedDescription as NSString,
                                                     title: "Impossible de télécharger le dossier")
                              })

        restClient.getAnnotations(dossier: folder.identifier,
                                  onResponse: {
                                      (annotation: [Annotation]) in
                                  },
                                  onError: {
                                      (error: Error) in
                                  })
    }


    private func downloadPdf(documentIndex: Int) {

        guard let folder = currentFolder,
              let restClient = self.restClient,
              (documentIndex < folder.documents.count),
              (documentIndex >= 0) else { return }

        let document = folder.documents[documentIndex]

        // Prepare

        let localFileUrl: URL?
        do {
            localFileUrl = try getLocalFileUrl(dossierId: folder.identifier, documentName: document.identifier)
        } catch {
            ViewUtils.logError(message: "Impossible d'écrire sur le disque", title: "Téléchargement échoué")
            return
        }

        // Download

        restClient.downloadFile(document: document.identifier,
                                isPdf: true,
                                path: localFileUrl!,
                                onResponse: {
                                    (response: String) in
                                    os_log("Download ok : %@", response)
                                },
                                onError: {
                                    (error: Error) in
                                    ViewUtils.logError(message: error.localizedDescription as NSString, title: "Téléchargement échoué")
                                }
        )
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