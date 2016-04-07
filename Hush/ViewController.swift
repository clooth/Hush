//
//  ViewController.swift
//  Hush
//
//  Created by Nico Hämäläinen on 09/03/16.
//  Copyright © 2016 sizeof.io. All rights reserved.
//

import UIKit
import Result
import Bond

class ViewController: UITableViewController {
  var connection: IMAPConnection!
  var messageBodyCache: [UInt32: String] = [:]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.registerClass(MessagesListViewCell.self, forCellReuseIdentifier: "Cell")

    connection = IMAPConnection(hostname: "", port: 993)
    connection.connect("", password: "")
    
    connection.messages.lift().bindTo(tableView) { [unowned self] indexPath, dataSource, tableView in
      let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! MessagesListViewCell
      let message = dataSource[indexPath.section][indexPath.row]
      cell.message = message
      if let cachedBody = self.messageBodyCache[message.uid] {
        cell.detailTextLabel?.text = cachedBody
      } else {
        cell.messageRenderingOperation = self.connection.session.plainTextBodyRenderingOperationWithMessage(message, folder: "INBOX")
        cell.messageRenderingOperation?.start { [unowned self] body, error in
          self.messageBodyCache[message.uid] = body
          cell.detailTextLabel?.text = body
        }
      }
      
      return cell
    }
    
    // Update title too
    connection.messages.observe { self.navigationItem.title = "Hush (\($0.sequence.count))" }
    
    // Fetch next messages
    connection.fetchMessages(100)
  }
  
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    let row = indexPath.row
    if (row >= connection.messages.count-1) {
      connection.fetchMessages(100)
    }
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 50.0
  }
}