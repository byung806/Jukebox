//
//  String+Parentheses.swift
//  Jukebox
//
//  Created by Bryan Yung on 6/27/23.
//

import Foundation

extension String {
    
    func getWithoutParentheses() -> String {
        return self.replacingOccurrences(of: "\\s?[(][^(]*[)]\\s?", with: "", options: .regularExpression)
    }
    
}
