//
//  ClearButton.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/31/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI


struct ClearButton: ViewModifier {
    @Binding var text: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content

            if !text.isEmpty {
                Button(action: { self.text = "" }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                }
                .padding(.trailing, 8)
            }
        }
    }
}
