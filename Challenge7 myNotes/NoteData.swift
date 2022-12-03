//  NoteData.swift
//  Challenge7 myNotes
//  Created by Ahmed Shaban on 01/09/2022.

import UIKit

class Note: Codable {
    var title: String
    var text: String
    
    init(title: String, text: String) {
        self.title = title
        self.text = text
    }
}
