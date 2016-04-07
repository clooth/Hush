//
//  MessagesListViewCell.swift
//  Hush
//
//  Created by Nico Hämäläinen on 09/03/16.
//  Copyright © 2016 sizeof.io. All rights reserved.
//

import Foundation
import UIKit

class MessagesListViewCell: UITableViewCell {
  let titleFontSize: CGFloat = 12.0
  let subtitleFontSize: CGFloat = 12.0
  
  var message: MCOIMAPMessage? {
    didSet {
      self.updateInterface()
    }
  }
  var messageRenderingOperation: MCOIMAPMessageRenderingOperation?
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: "Cell")
    
    self.textLabel?.font = UIFont.boldSystemFontOfSize(titleFontSize)
    self.textLabel?.numberOfLines = 1
    self.detailTextLabel?.font = UIFont.systemFontOfSize(subtitleFontSize)
    self.detailTextLabel?.textColor = UIColor.grayColor()
    self.detailTextLabel?.numberOfLines = 1
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInterface() {
    if let message = message {
      textLabel?.text = message.header.subject
    }
  }
  
  override func prepareForReuse() {
    messageRenderingOperation?.cancel()
    self.detailTextLabel?.text = ""
  }
}