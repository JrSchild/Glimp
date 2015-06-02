//
//  HeaderCollectionViewCell.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 02-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class HeaderCollectionViewCell: UICollectionViewCell {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        
        var label = UILabel(frame: CGRectMake(20, 0, self.contentView.bounds.width, self.contentView.bounds.height))
        label.text = text
        label.font = UIFont(name: label.font.fontName, size: 13)
        self.contentView.addSubview(label)
    }
}

class AnswerHeaderCollectionViewCell : HeaderCollectionViewCell {
    
    let text = "ANSWER A GLIMP"
    
    init(frame: CGRect) {
        super.init(frame: frame, text: text)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class AskHeaderCollectionViewCell : HeaderCollectionViewCell {
    
    let text = "ASK A GLIMP"
    
    init(frame: CGRect) {
        super.init(frame: frame, text: text)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
