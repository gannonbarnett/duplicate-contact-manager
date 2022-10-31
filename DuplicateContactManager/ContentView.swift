//
//  ContentView.swift
//  DuplicateContactManager
//
//  Created by Gannon Barnett on 6/12/22.
//

import SwiftUI
import Foundation
import Contacts
import StoreKit

struct ContentView: View {
    @ObservedObject var analyzer = ContactAnalyzer()
    var body: some View {
        VStack(alignment: .center, spacing: 0.0) {
            Text("Gannon's Contact Manager").font(Font.title)
            Text(analyzer.GetSummary()).font(Font.headline)
            Divider()
            List(Array((analyzer.LastFreqMap ?? [:]).keys.sorted()), id:\.self) { k in
                HStack {
                    Text(k)
                    Spacer()
                    Text(String(analyzer.LastFreqMap![k]!.count))
                }
            }
            Divider()
            HStack(alignment: .center) {
                Button(action: analyzer.SyncContactsAnalysis) {
                    Text("SYNC")
                }.frame(alignment: .center).padding()
                Spacer()
                Button(action: analyzer.Prune) {
                    Text("PRUNE")
                }.frame(alignment: .center).padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
