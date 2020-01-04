//
//  SettingsView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/2/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel()

    @Environment(\.presentationMode) var presentationMode

    @State var showingActionSheet = false

    var body: some View {
        GeometryReader { geom in
            VStack {
                Text("Settings")
                    .font(.custom("Arial", size: 40))
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)

                Form {
                    Section(header: Text("Authorization")) {
                        LabeledTextField("API Key", placeholder: "token", field: self.$settingsVM.apiKey)
                    }

                    Section(header: Text("Credits")) {
                        Text("...put some credits here...")
                    }
                }
                Button(action: { self.showingActionSheet = true }) {
                    Text("Exit")
                        .frame(width: geom.size.width - 80)
                        .padding()
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(.infinity)
                        .padding()
                }
            }
            .actionSheet(isPresented: self.$showingActionSheet) {
                ActionSheet(title: Text("Save Settings"), buttons: [
                    .default(Text("Save")) {
                        self.settingsVM.save()
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    .default(Text("Exit without saving")) {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    .cancel()
                ])
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


struct LabeledTextField: View {
    var label: String
    var placeholder: String
    var field: Binding<String>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: field).multilineTextAlignment(.trailing)
        }
    }

    init(_ label: String, placeholder: String? = nil, field: Binding<String>) {
        self.label = label
        self.field = field
        if let placeholder = placeholder {
            self.placeholder = placeholder
        } else {
            self.placeholder = label
        }
    }
}
