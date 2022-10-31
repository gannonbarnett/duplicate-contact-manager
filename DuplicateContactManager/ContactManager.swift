//
//  ContactManager.swift
//  DuplicateContactManager
//
//  Created by Gannon Barnett on 9/10/22.
//

import SwiftUI
import Foundation
import Contacts
import StoreKit

func GetUniqueNames(_ analysis: [String: [CNContact]]?) -> Int {
    if analysis == nil {
        return 0
    }
    var exactNameMatches = 0
    for (_, contacts) in analysis! {
        if contacts.count > 1 {
            exactNameMatches += 1
        }
    }
    return exactNameMatches
}

class ContactAnalyzer : ObservableObject {
    @Published var Logs : [String] = []
    @Published var LastFreqMap : [String: [CNContact]]? = nil

    init() {
        log("analyzer init")
        Task {
            await self.RequestAccess()
        }
    }
    
    func log(_ s: String) {
        self.Logs.append(s)
    }
    
    func GetSummary() -> String {
        if self.LastFreqMap == nil {
            return "No data"
        }
        var count = 0
        var dups = 0
        for (k, v) in self.LastFreqMap! {
            count += v.count
            if v.count > 1 {
                dups += 1
            }
        }
        return "\(count) contacts, \(LastFreqMap!.keys.count) unique. \(Int(Double(dups)/Double(LastFreqMap!.keys.count)*100))% of contacts are duplicated."
    }
    
    func RequestAccess() async {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case .authorized:
            log("access request authorized")
            break
        case .notDetermined, .restricted:
            do {
                try await store.requestAccess(for: .contacts)
            } catch let error {
                log("failed to request access \(error)")
            }
        case .denied:
            log("contacts access required")
        default:
            log("default reached")
        }
    }
    
    func SyncContactsAnalysis() {
        let store = CNContactStore()
        var totalContacts = 0
        var contactFreq : [String: [CNContact]] = [:]

        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        log("sync contacts start")
        do {
            try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                totalContacts += 1
                let key: String = "\(contact.givenName) \(contact.familyName)"
                if contactFreq[key] == nil {
                    contactFreq[key] = []
                }
                contactFreq[key]!.append(contact)
            })
        } catch let error {
            log("failed to sync contacts \(error)")
        }
        
        self.LastFreqMap = contactFreq
    }
    
    func Prune() {
        if self.LastFreqMap == nil {
            log("prune exit: no data")
            return
        }
        let keys = Array(self.LastFreqMap!.keys.sorted())
        var contacts : [CNContact] = []
        for k in keys {
            contacts = self.LastFreqMap![k]!
            if contacts.count > 1 {
                let req = CNSaveRequest()
                for i in 1...contacts.count-1 {
                    req.delete(contacts[i].mutableCopy() as! CNMutableContact)
                }
                
                do {
                    try CNContactStore().execute(req)
                    log("req success")
                } catch let error {
                    log("error executing req \(error)")
                }
            }
        }
    }
}
