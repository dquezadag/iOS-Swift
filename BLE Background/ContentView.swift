//
//  ContentView.swift
//  BLE Background
//
//  Created by Darwin Quezada Gaibor on 10/24/20.
//

import SwiftUI

struct BigText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 20, design: .rounded))
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}

struct ContentView: View {
    var body: some View {
        Text("Buscando beacons y BLE \n revisar en la consola ...")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
