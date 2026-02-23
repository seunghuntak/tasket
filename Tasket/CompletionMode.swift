//
//  CompletionMode.swift
//  MyFirstApp
//
//  Created by 탁승훈 on 2/19/26.
//


import Foundation

enum CompletionMode: String, CaseIterable, Identifiable {
    case circleOnly
    case swipeOnly
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circleOnly: return "Circle only"
        case .swipeOnly:  return "Swipe only"
        case .both:       return "Both"
        }
    }
}
