//
//  PawNovaBundle.swift
//  PawNova Widget Extension
//
//  Widget bundle including home screen widgets and Live Activities.
//

import WidgetKit
import SwiftUI

@main
struct PawNovaWidgetBundle: WidgetBundle {
    var body: some Widget {
        PawNovaWidget()
        PawNovaLiveActivity()
    }
}
