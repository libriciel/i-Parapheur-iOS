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
import Alamofire

class DeskListController: UITableViewController, UISplitViewControllerDelegate {

    @IBOutlet weak var accountButton: UIBarButtonItem!

    var restClient: RestClient?
    var bureauxArray: [Bureau] = []
    var loading = true


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("View Loaded : MasterViewController")

        // Patch Accounts
        ModelsDataController.loadManagedObjectContext()

        updateVersionNumberInSettings()

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onModelsCoreDataLoaded),
                name: ModelsDataController.notificationModelsDataControllerLoaded,
                object: nil)

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onAccountSelected),
                name: AccountSelectionController.NotifSelected,
                object: nil)

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onAccountSelected),
                name: FirstLoginPopupController.NotifDismiss,
                object: nil)

        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = ColorUtils.selectedCellGrey
        refreshControl?.addTarget(
                self,
                action: #selector(self.loadBureaux),
                for: .valueChanged)
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="UI Listeners"> MARK: - UI Listeners


    @IBAction func onSettingsButtonClicked(_ sender: Any) {
        os_log("onSettingsButtonClicked")
        // TODO : Direct call to login popup, on no-account set

        // Displays secondary Settings.storyboard
        // TODO : Switch to easier linked Storyboard
        // (When iOS9 will be the oldest supported version)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        let settingsViewController = settingsStoryboard.instantiateInitialViewController()!
        settingsViewController.modalTransitionStyle = .coverVertical

        present(settingsViewController, animated: true, completion: nil)
    }


    @IBAction func onAccountButtonClicked(_ sender: Any) {
        os_log("onAccountButtonClicked")

        let selectedAccountId = UserDefaults.standard.string(forKey: Account.preferenceKeySelectedAccount)
        let areSettingsSet = (selectedAccountId != nil)

        if (areSettingsSet) {
            performSegue(withIdentifier: AccountSelectionController.Segue, sender: self)
        }
        else {
            performSegue(withIdentifier: FirstLoginPopupController.Segue, sender: self)
        }
    }


    // </editor-fold desc="UI Listeners">


    // <editor-fold desc="Listeners"> MARK: - Listeners


    @objc private func onModelsCoreDataLoaded() {

        ModelsDataController.cleanupAccounts(preferences: UserDefaults.standard)

        // Settings check

        let selectedAccountId = UserDefaults.standard.string(forKey: Account.preferenceKeySelectedAccount)
        let areSettingsSet = (selectedAccountId != nil)

        refreshAccountIcon(isAccountSet: areSettingsSet)

        // First launch behavior.
        // We can't do it on viewDidLoad, we can display a modal view only here.

        if (areSettingsSet) {
            initRestClient()
        }
        else {
            performSegue(withIdentifier: FirstLoginPopupController.Segue as String, sender: self)
        }
    }


    @objc private func onAccountSelected() {

        // Popup response

        let preferences = UserDefaults.standard
        let selectedAccountId = preferences.string(forKey: Account.preferenceKeySelectedAccount)
        let areSettingsSet = selectedAccountId != nil

        // Check

        refreshAccountIcon(isAccountSet: areSettingsSet)
        initRestClient()
    }


    // </editor-fold desc="Listeners">


    @objc func loadBureaux() {
        refreshControl?.beginRefreshing()

        self.restClient?.getDesks(
                onResponse:
                { (desks: [Bureau]) in

                    self.bureauxArray = desks
                    self.loading = false
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                },
                onError: { (error: Error) in

                    self.bureauxArray = []
                    self.loading = false
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    ViewUtils.logError(message: error.localizedDescription as NSString, title: "Le chargement des bureaux a échoué")
                }
        )
    }


    private func initRestClient() {

        let accountSelectedId = UserDefaults.standard.string(forKey: Account.preferenceKeySelectedAccount as String) ?? Account.demoId
        let accounts = ModelsDataController.fetchAccounts()
        let selectedAccount = accounts.filter { $0.id == accountSelectedId }[0]

        initRestClient(url: selectedAccount.url!,
                       login: selectedAccount.login!,
                       password: selectedAccount.password!)
    }


    private func initRestClient(url: String,
                                login: String,
                                password: String) {

        checkDemonstrationServer()

        restClient = RestClient(baseUrl: url as NSString, login: login as NSString, password: password as NSString)
        restClient?.getApiVersion(
                onResponse:
                { (number: NSNumber) in

                    self.loadBureaux()
                },
                onError: { (error: Error) in

                    let nsError = error as NSError
                    self.refreshControl?.endRefreshing()
                    self.bureauxArray = []
                    self.tableView?.reloadData()

                    // New test when network retrieved
                    if (nsError.code == NSURLErrorNotConnectedToInternet) {
                        self.setNewConnectionTryOnNetworkRetrieved()
                        ViewUtils.logInfo(message: "Une connexion Internet est nécessaire au lancement de l'application.", title: nil)
                    }
                    else {
                        ViewUtils.logError(message: StringsUtils.getMessage(error: nsError), title: nil)
                    }
                }
        )
    }


    private func setNewConnectionTryOnNetworkRetrieved() {

        let manager = NetworkReachabilityManager(host: "www.apple.com")

        manager?.listener = { status in

            switch status {

                case .reachable(.ethernetOrWiFi),
                     .reachable(.wwan):
                    os_log("The network is reachable over the WiFi connection")

                    self.refreshControl?.beginRefreshing()
                    // self.tableView.setContentOffset(CGPointMake(0, strongSelf.tableView.contentOffset.y - strongSelf.refreshControl.frame.size.height), animated: true)
                    self.initRestClient()
                    manager?.stopListening()

                default:
                    os_log("The network is not reachable yet")
            }
        }

        manager?.startListening()
    }


    private func checkDemonstrationServer() {

        if (!ViewUtils.isConnectedToDemoAccount()) {
            return
        }

        // Check UTC time, and warns for possible shutdowns
        let currentDate = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "H"

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let hour = numberFormatter.number(from: dateFormatter.string(from: currentDate)) ?? 0

        ViewUtils.logInfo(message: "L'application est actuellement liée au parapheur de démonstration.", title: nil)

        if ((hour.intValue > 23) || (hour.intValue < 7)) {
            ViewUtils.logWarning(message: "Le parapheur de démonstration peut être soumis à des déconnexions, entre minuit et 7h du matin (heure de Paris).", title: nil)
        }
    }


    private func refreshAccountIcon(isAccountSet: Bool) {
        accountButton.tintColor = isAccountSet ? ColorUtils.aqua : ColorUtils.salmon
    }


    private func updateVersionNumberInSettings() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        UserDefaults.standard.set(version, forKey: "version_preference")
    }


    // <editor-fold desc="UITableViewDataSource & UITableViewDelegate"> MARK: - UITableViewDataSource & UITableViewDelegate


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (bureauxArray.count == 0) {
            tableView.backgroundView = DeskListEmptyView.instanceFromNib()
            tableView.tableFooterView?.isHidden = true
        }

        else {
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
        }

        return bureauxArray.count
    }

    /**
        Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier
        and querying for available reusable cells with dequeueReusableCellWithIdentifier:
        Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let bureau = bureauxArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: DeskListCell.cellId,
                                                 for: indexPath) as! DeskListCell

        // Folders to do

        if (bureau.aTraiter == 0) {
            cell.foldersToDo.text = "Aucun dossier à traiter"
        }
        else if (bureau.aTraiter == 1) {
            cell.foldersToDo.text = "1 dossier à traiter"
        }
        else {
            cell.foldersToDo.text = String(format: "%ld dossiers à traiter", bureau.aTraiter)
        }

        // Delegations

        if (bureau.dossiersDelegues > 0) {
            cell.foldersToDo.text = String(format: "%@, %ld en délégation", cell.foldersToDo.text!, bureau.dossiersDelegues)
        }

        // Late Folders

        cell.lateFolders.isHidden = (bureau.enRetard == 0)

        if (bureau.aTraiter == 1) {
            cell.lateFolders.text = "1 dossier en retard"
        }
        else {
            cell.lateFolders.text = String(format: "%ld dossiers en retard", bureau.enRetard)
        }

        //

        cell.title.text = bureau.name
        cell.disclosureIndicator.image = cell.disclosureIndicator.image?.withRenderingMode(.alwaysTemplate)
        cell.dot.image = cell.dot.image?.withRenderingMode(.alwaysTemplate)

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let bureau = bureauxArray[indexPath.row]
        os_log("Selected Desk = %@", bureau.nodeRef!)

        let controller = storyboard?.instantiateViewController(withIdentifier: "DeskViewController") as! FolderListController
        navigationController?.pushViewController(controller, animated: true)

        controller.currentDesk = bureau
        controller.restClient = restClient
        controller.navigationItem.title = bureau.name
    }


    // </editor-fold desc="UITableViewDataSource & UITableViewDelegate">

}
