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
import UIKit
import os


protocol FolderListDelegate: class {

    func onFolderSelected(_ folder: Dossier, desk: Bureau, restClient: RestClient)

    func onFolderMultipleSelectionStarted()

    func onFolderMultipleSelectionEnded()

}


class FolderListController: UITableViewController, UISearchResultsUpdating {


    private static let pageSize = 15

    @IBOutlet weak var negativeToolbarButton: UIBarButtonItem!
    @IBOutlet weak var positiveToolbarButton: UIBarButtonItem!
    @IBOutlet weak var loadMoreButton: UIButton!

    var restClient: RestClient?
    var currentDesk: Bureau?
    var currentDossier: Dossier?
    var dossiers: [Dossier] = []
    var filteredDossiers: [Dossier] = []
    var selectedDossiers: [Dossier] = []
    var currentPage = 0
    let searchController = UISearchController(searchResultsController: nil)


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View Loaded : DeskViewController")

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.refresh),
                name: WorkflowDialogController.notificationActionComplete,
                object: nil)

        // UI

        let topBackgroundColor = ColorUtils.veryLightGrey
        let topTextColor = ColorUtils.blue

        navigationItem.backBarButtonItem?.tintColor = topTextColor

        // Refresh control

        refreshControl = ColorizedRefreshControl()
        refreshControl?.backgroundColor = topBackgroundColor
        refreshControl?.tintColor = ColorUtils.lightGrey
        refreshControl?.addTarget(self, action: #selector(self.refresh), for: .valueChanged)

        // Setup UISearchController

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.backgroundColor = topBackgroundColor
        searchController.searchBar.barTintColor = topBackgroundColor
        searchController.searchBar.tintColor = topTextColor
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true

        //

        loadDossiers(page: currentPage)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

//        if segue.identifier == "filterSegue" {
//            // FIXME ((ADLFilterViewController *) segue.destinationViewController).delegate = self;
//        }

        if segue.identifier == WorkflowDialogController.segue,
           let destinationController = segue.destination as? WorkflowDialogController,
           let action = sender as? Action,
           let desk = currentDesk {

            var actionsToPerform: [ActionToPerform] = []
            selectedDossiers.forEach { actionsToPerform.append(ActionToPerform(folder: $0, action: action)) }

            // Launch popup

            destinationController.restClient = restClient
            destinationController.currentAction = action
            destinationController.actionsToPerform = actionsToPerform
            destinationController.currentDeskId = desk.identifier
        }
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI Listeners"> MARK: - UI Listeners


    @IBAction func onPositiveButtonClicked(_ sender: Any) {

        guard let possibleAction = Dossier.getPositiveAction(folders: selectedDossiers) else {
            ViewUtils.logError(message: "Vous ne pouvez pas effectuer cette action sur tablette.",
                               title: "Action impossible")
            return
        }

        performSegue(withIdentifier: WorkflowDialogController.segue, sender: possibleAction)
    }


    @IBAction func onNegativeButtonClicked(_ sender: Any) {

        guard let negativeAction = Dossier.getNegativeAction(folders: selectedDossiers) else {
            ViewUtils.logError(message: "Vous ne pouvez pas effectuer cette action sur tablette.",
                               title: "Action impossible")
            return
        }

        performSegue(withIdentifier: WorkflowDialogController.segue, sender: negativeAction)
    }


    @IBAction func onFilterButtonClicked(_ sender: Any) {
    }


    @IBAction func onLoadMoreButtonClicked(_ sender: Any) {
        currentPage += 1
        loadDossiers(page: currentPage)
    }


    // </editor-fold desc="UI Listeners">


    private func refreshSelectionUI() {

        if selectedDossiers.count == 1 {
            navigationItem.title = "1 dossier sélectionné"
        }
        else {
            navigationItem.title = String(format: "%d dossiers sélectionnés", selectedDossiers.count)
        }

        let positiveAction = Dossier.getPositiveAction(folders: selectedDossiers)
        let negativeAction = Dossier.getNegativeAction(folders: selectedDossiers)

        positiveToolbarButton.isEnabled = positiveAction != nil
        negativeToolbarButton.isEnabled = negativeAction != nil

        positiveToolbarButton.title = Action.prettyPrint(positiveAction ?? .visa)
        negativeToolbarButton.title = Action.prettyPrint(negativeAction ?? .reject)
    }


    private func updateSelectionMode() {

        // Fetch cells and toggle dot/check

        for cell in tableView.visibleCells as! [FolderListCell] {
            cell.checkboxHandlerView.isHidden = (selectedDossiers.count == 0)
            cell.dot.isHidden = (selectedDossiers.count != 0)
            cell.selectionStyle = (selectedDossiers.count == 0) ? .default : .none

            // Seems useless, but fixes a cell recycle UI problem,
            // when the selection mode is icon-exited and re-activated.
            if selectedDossiers.count == 0 {
                cell.checkOnImage.isHidden = true
                cell.checkOffImage.isHidden = false
            }
        }

        // Re-select previously selected cell

        if selectedDossiers.count == 0 {

            var index: IndexPath? = nil

            for i in 0..<filteredDossiers.count {
                if filteredDossiers[i].identifier == currentDossier?.identifier {
                    index = IndexPath(row: i, section: 0)
                }
            }

            if index != nil {
                tableView.selectRow(at: index, animated: false, scrollPosition: .none)
            }
        }

        // Update UI

        let splitViewController = view.window?.rootViewController as? UISplitViewController
        let rightNavigationController = splitViewController?.viewControllers.last as? UINavigationController
        let folderListDelegate = rightNavigationController?.topViewController as? FolderListDelegate

        if selectedDossiers.count != 0 {

            let exitButton = UIBarButtonItem()
            exitButton.title = "Annuler"
            exitButton.image = UIImage(named: "ic_close_white.png")
            exitButton.tintColor = ColorUtils.aqua
            exitButton.style = .plain
            exitButton.target = self
            exitButton.action = #selector(self.exitSelection)

            navigationItem.leftBarButtonItem = exitButton
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.tintColor = UIColor.clear

            folderListDelegate?.onFolderMultipleSelectionStarted()
            navigationController?.setToolbarHidden(false, animated: true)
        }
        else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.tintColor = ColorUtils.aqua
            navigationItem.title = currentDesk?.name

            folderListDelegate?.onFolderMultipleSelectionEnded()
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }


    @objc private func exitSelection() {
        selectedDossiers.removeAll()
        updateSelectionMode()
    }


    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        loadDossiers(page: 0)
        exitSelection()
    }


    private func loadDossiers(page: Int) {

        // FIXME NSDictionary *currentFilter = ADLSingletonState.sharedSingletonState.currentFilter;
        let currentFilter: [String: String]? = nil

        if currentFilter != nil {
// FIXME
//            let types = []
//            for (NSString *type in currentFilter["types"])
//            [types addObject:@ {
//                @ "ph:typeMetier": type
//            }];
//
//            NSMutableArray *sousTypes = NSMutableArray.new;
//            for (NSString *sousType in currentFilter[@ "sousTypes"])
//            [sousTypes addObject:@{
//            @"ph:soustypeMetier": sousType
//            }];
//
//            NSDictionary *titre = @ {
//                @ "or": @ [@ {
//                    @ "cm:title": [NSString stringWithFormat:@ "*%@*",
//                    currentFilter[@ "titre"]]
//                }]
//            };
//            NSDictionary *filtersDictionary = @ {
//                @ "and": @ [@ {
//                    @ "or": types
//                }, @ {
//                    @ "or": sousTypes
//                }, titre]
//            };
//
//            // Send request
//
//            // Stringify JSON filter
//
//            NSError *error;
//            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtersDictionary
//            options:0
//            error:&error];
//
//            NSString *jsonString = nil;
//            if (jsonData)
//            jsonString = [[NSString alloc] initWithData:jsonData
//            encoding:NSUTF8StringEncoding];
//
//            // Request
//
//            restDossier.getDossiers()
//
//            [_restClient getDossiers:_desk.nodeRef
//            page:page
//            size:15
//            filter:jsonString
//            success:^(NSArray *dossiers) {
//                __strong typeof(weakSelf) strongSelf = weakSelf;
//                if (strongSelf) {
//                    NSLog(@ "getDossiers success : %lu", (unsigned long) dossiers.count);
//                    [strongSelf.refreshControl endRefreshing];
//                    HIDE_HUD
//                    [strongSelf getDossierDidEndWithSuccess:dossiers];
//                }
//            }
//            failure:^(NSError *getDossiersError) {
//                __strong typeof(weakSelf) strongSelf = weakSelf;
//                if (strongSelf) {
//                    [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
//                    title:nil];
//                    [strongSelf.refreshControl endRefreshing];
//                    HIDE_HUD
//                }
//            }];
        }
        else {
            restClient?.getDossiers(bureau: (currentDesk?.nodeRef)!,
                                    page: page,
                                    size: FolderListController.pageSize,
                                    filterJson: nil,
                                    onResponse:
                                    { (newFolders: [Dossier]) in

                                        os_log("getDossiers success : %d", newFolders.count)
                                        self.refreshControl?.endRefreshing()
                                        self.getDossierDidEndWithSuccess(newDossiers: newFolders)
                                    },
                                    onError: { (error: Error) in

                                        ViewUtils.logError(message: StringsUtils.getMessage(error: error as NSError), title: nil)
                                        self.refreshControl?.endRefreshing()
                                    }
            )
        }
    }


    private func getDossierDidEndWithSuccess(newDossiers: [Dossier]) {

        // Updating results

        if currentPage == 0 {
            dossiers.removeAll()
        }

        dossiers.append(contentsOf: newDossiers)

        // Updating UI

        loadMoreButton.isHidden = (newDossiers.count != FolderListController.pageSize)
        updateSearchResults(for: searchController)
    }


    // <editor-fold desc="UITableView"> MARK: - UITableView


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if filteredDossiers.count == 0 {
            let emptyView = FolderListEmptyView()
            // FIXME emptyView.filterAlertLabel.isHidden = (dossiers.count > 0)

            tableView.backgroundView = emptyView
            tableView.tableFooterView?.isHidden = true
        }
        else {
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
        }

        return filteredDossiers.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: FolderListCell.cellIdentifier) as! FolderListCell
        let dossier = filteredDossiers[indexPath.row]

        // UI fix

        if cell.dot.image?.renderingMode != .alwaysTemplate {
            cell.checkOffImage.image = cell.checkOffImage.image?.withRenderingMode(.alwaysTemplate)
            cell.checkOnImage.image = cell.checkOnImage.image?.withRenderingMode(.alwaysTemplate)
            cell.dot.image = cell.dot.image?.withRenderingMode(.alwaysTemplate)
        }

        // Selected state

        cell.selectionStyle = (selectedDossiers.count == 0) ? .default : .none
        cell.checkboxHandlerView.isHidden = (selectedDossiers.count == 0)
        cell.dot.isHidden = (selectedDossiers.count != 0)

        let isSelected = selectedDossiers.contains(dossier)
        cell.checkOffImage.isHidden = isSelected
        cell.checkOnImage.isHidden = !isSelected

        // Adapter

        cell.dot.tintColor = dossier.isDelegue ? ColorUtils.darkPurple : ColorUtils.lightGrey
        cell.titleLabel.text = dossier.title
        cell.typologyLabel.text = String(format: "%@ / %@", dossier.type, dossier.subType)

        // Date

        cell.limitDateLabel.isHidden = (dossier.limitDate == nil)

        if dossier.limitDate != nil {
            let isLate = (dossier.limitDate?.compare(Date()) == .orderedAscending)

            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .short
            outputFormatter.timeStyle = .none

            let datePrint = isLate ? "en retard depuis le %@" : "à rendre avant le %@"
            cell.limitDateLabel.text = String(format: datePrint, outputFormatter.string(from: dossier.limitDate!))

            cell.limitDateLabel.textColor = isLate ? ColorUtils.salmon : ColorUtils.blueGreySeparator
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! FolderListCell
        let dossierClicked = filteredDossiers[indexPath.row]

        // Selection mode

        if selectedDossiers.count != 0 {

            // Update cell

            if selectedDossiers.contains(dossierClicked) {
                selectedDossiers = selectedDossiers.filter { $0 != dossierClicked }
                cell.checkOnImage.isHidden = true
                cell.checkOffImage.isHidden = false
            }
            else {
                selectedDossiers.append(dossierClicked)
                cell.checkOnImage.isHidden = false
                cell.checkOffImage.isHidden = true
            }

            // Update UI

            refreshSelectionUI()

            if selectedDossiers.count == 0 {
                updateSelectionMode()
            }

            return
        }

        // Check re-selection, and throw event

        if dossierClicked == currentDossier {
            return
        }

        let splitViewController = view.window?.rootViewController as? UISplitViewController
        let rightNavigationController = splitViewController?.viewControllers.last as? UINavigationController
        let folderListDelegate = rightNavigationController?.topViewController as? FolderListDelegate

        guard let currentRestClient = restClient,
              let currentDesk = currentDesk else { return }

        currentDossier = dossierClicked
        folderListDelegate?.onFolderSelected(dossierClicked, desk: currentDesk, restClient: currentRestClient)
    }


    @IBAction func onTableCellLongPressed(_ sender: UILongPressGestureRecognizer) {

        if sender.state != .began {
            return
        }

        let indexPathPoint = sender.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: indexPathPoint)

        // Long press on table view but not on a row

        if indexPath == nil {
            return
        }

        // Default case

        // Those two lines are there to release the gesture event.
        // Otherwise, the long press is always called at every frame.
        // It looks like a very poor solution, it smells like a very poor solution,
        // but it's recommended by Apple there : https://developer.apple.com/videos/play/wwdc2014/235/
        // So... I guess it's the way to do it...
        sender.isEnabled = false
        sender.isEnabled = true
        // End of the gesture release event.

        // Refresh data

        let dossier = filteredDossiers[indexPath!.row]

        if selectedDossiers.contains(dossier) {
            selectedDossiers = selectedDossiers.filter { $0 != dossier }
        }
        else {
            selectedDossiers.append(dossier)
        }

        // Refresh UI

        tableView.reloadRows(at: [indexPath!], with: .none)

        refreshSelectionUI()
        updateSelectionMode()
    }


    func updateSearchResults(for searchController: UISearchController) {
        filteredDossiers = dossiers.filter({ (searchController.searchBar.text! == "") || $0.title!.lowercased().contains(searchController.searchBar.text!.lowercased()) })
        tableView.reloadData()
    }


    // </editor-fold desc="UITableView">

}
