//
//  NewLineViewController.swift
//  MacTransit
//
//  Created by Adam Boyd on 2016-11-19.
//  Copyright © 2016 adam. All rights reserved.
//

import Cocoa
import SwiftBus

protocol NewStopDelegate: class {
    func newStopControllerDidAdd(newEntry: TransitEntry)
}

class NewLineViewController: NSViewController {
    
    @IBOutlet weak var agencyPopUpButton: NSPopUpButton!
    @IBOutlet weak var routePopUpButton: NSPopUpButton!
    @IBOutlet weak var directionPopUpButton: NSPopUpButton!
    @IBOutlet weak var stopPopUpButton: NSPopUpButton!
    @IBOutlet weak var addStopButton: NSButton!
    @IBOutlet weak var allTimesCheckBox: NSButton!
    @IBOutlet weak var startTimeDatePicker: NSDatePicker!
    @IBOutlet weak var endTimeDatePicker: NSDatePicker!
    
    weak var delegate: NewStopDelegate?
    var agencies: [TransitAgency] = []
    var routes: [TransitRoute] = []
    var directions: [String] = []
    var stops: [TransitStop] = []
    var selectedRoute: TransitRoute?
    var selectedStop: TransitStop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.agencyPopUpButton.action = #selector(self.agencySelectedAction)
        self.routePopUpButton.action = #selector(self.routeSelectedAction)
        self.directionPopUpButton.action = #selector(self.directionSelectedAction)
        self.stopPopUpButton.action = #selector(self.stopSelectedAction)
        
        SwiftBus.shared.transitAgencies() { agencies in
            var inOrderAgencies = Array(agencies.values)
            
            //Ordering the routes alphabetically
            inOrderAgencies = inOrderAgencies.sorted {
                $0.agencyTitle.localizedCaseInsensitiveCompare($1.agencyTitle) == ComparisonResult.orderedAscending
            }
            
            self.agencies = inOrderAgencies
            self.agencyPopUpButton.addItems(withTitles: inOrderAgencies.map({ $0.agencyTitle }))
        }
    }
    
    @IBAction func allTimesCheckboxClicked(_ sender: Any) {
        self.startTimeDatePicker.isEnabled = !self.startTimeDatePicker.isEnabled
        self.endTimeDatePicker.isEnabled = !self.endTimeDatePicker.isEnabled
    }
    
    // MARK: - Actions from the popup buttons
    
    func agencySelectedAction() {
        self.routePopUpButton.removeAllItems()
        self.routes = []
        self.selectedRoute = nil
        self.directionPopUpButton.removeAllItems()
        self.directions = []
        self.stopPopUpButton.removeAllItems()
        self.stops = []
        self.addStopButton.isEnabled = false
        
        let agency = self.agencies[self.agencyPopUpButton.indexOfSelectedItem]
        SwiftBus.shared.routes(forAgency: agency) { routes in
            var inOrderRoutes = Array(routes.values)
            
            //Ordering the routes alphabetically
            inOrderRoutes = inOrderRoutes.sorted {
                $0.routeTitle.localizedCaseInsensitiveCompare($1.routeTitle) == ComparisonResult.orderedAscending
            }
            
            self.routes = inOrderRoutes
            self.routePopUpButton.addItems(withTitles: inOrderRoutes.map({ $0.routeTitle }))
        }
    }
    
    func routeSelectedAction() {
        self.selectedRoute = nil
        self.directionPopUpButton.removeAllItems()
        self.directions = []
        self.stopPopUpButton.removeAllItems()
        self.stops = []
        self.addStopButton.isEnabled = false
        
        let selectedRoute = self.routes[self.routePopUpButton.indexOfSelectedItem]
        SwiftBus.shared.configuration(forRoute: selectedRoute) { route in
            guard let route = route else { return }
            
            self.selectedRoute = route
            //The keys to this array are all possible directions
            self.directionPopUpButton.addItems(withTitles: Array(route.stopsOnRoute.keys))
        }
    }
    
    
    /// User selected a direction for the direction popup
    func directionSelectedAction() {
        self.stopPopUpButton.removeAllItems()
        self.stops = []
        self.addStopButton.isEnabled = false
        
        if let title = self.directionPopUpButton.selectedItem?.title, let stops = self.selectedRoute?.stopsOnRoute[title] {
            //Getting the stops for that direction. The direction is the key to the dictionary for the stops on that route
            self.stopPopUpButton.addItems(withTitles: stops.map({ $0.stopTitle }))
        }
    }
    
    func stopSelectedAction() {
        self.addStopButton.isEnabled = true
    }
    
    @IBAction func addNewStop(_ sender: Any) {
        guard let stop = self.selectedStop else { return }
        var times: (Date, Date)? = nil
        
        //If the pickers are enabled, get the times
        if self.startTimeDatePicker.isEnabled && self.endTimeDatePicker.isEnabled {
            times?.0 = self.startTimeDatePicker.dateValue
            times?.1 = self.endTimeDatePicker.dateValue
        }
        
        let entry = TransitEntry(stop: stop, times: times)
        self.delegate?.newStopControllerDidAdd(newEntry: entry)
    }
}