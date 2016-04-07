//
//  IMAPConnection.swift
//  Hush
//
//  Created by Nico Hämäläinen on 09/03/16.
//  Copyright © 2016 sizeof.io. All rights reserved.
//

import Foundation
import BrightFutures
import Bond

/// Handles the connection and message fetching of a single IMAP account
class IMAPConnection
{
  /// The hostname of the IMAP server
  var hostname: String

  /// The IMAP server's port
  var port: Int
  
  /// Currently downloaded message count
  var totalNumberOfMessages: Int = 0
  
  /// Currently downloaded messages
  var messages = ObservableArray<MCOIMAPMessage>()
  
  /// The underlying IMAP session
  var session: MCOIMAPSession
  
  /// The underlying message fetching request type
  private var messagesRequestKind: MCOIMAPMessagesRequestKind
  
  /// The underlying message fetching request
  private var fetchMessagesOperation: MCOIMAPFetchMessagesOperation!
  
  /// Create a new IMAPConnection with the given hostname and port
  ///
  /// - parameter hostname: The IMAP server's host
  /// - parameter port: The IMAP server's port
  ///
  /// - returns: Your brand new (yet still unconnected) IMAP connection
  init(hostname: String, port: Int) {
    self.hostname = hostname
    self.port = port
    self.session = MCOIMAPSession()
    self.messagesRequestKind = [.Headers, .ExtraHeaders, .Flags, .FullHeaders, .HeaderSubject, .Structure, .Uid, .Size]
  }
  
  /// Login to the IMAP server with a username and password
  ///
  /// - parameter username: The username (usually email address) of the account
  /// - parameter password: The password of the account
  func connect(username: String, password: String) -> Self {
    self.session.username = username
    self.session.password = password
    setupIMAPSession()
    return self
  }
  
  /// Login to the IMAP server with a username and oauth2 access token
  ///
  /// - parameter username: The username (usually email address) of the account
  /// - parameter accessToken: The oauth2 access token for the account
  func connect(username: String, accessToken: String) -> Self {
    self.session.username = username
    self.session.password = nil
    self.session.OAuth2Token = accessToken
    self.session.authType = MCOAuthType.XOAuth2
    setupIMAPSession()
    return self
  }
  
  /// Download the folders in the current account
  func fetchFolders() -> Future<[MCOIMAPFolder], NSError> {
    let promise = Promise<[MCOIMAPFolder], NSError>()
    
    // Fetch all folders from the server
    let operation = self.session.fetchAllFoldersOperation()
    operation.start { error, folders in
      guard let folders = folders as? [MCOIMAPFolder] else {
        return promise.failure(error ?? HushError.Unknown.NSError)
      }
      
      /// All good!
      promise.success(folders)
    }
    
    return promise.future
  }
  
  func fetchFolderInfo(folderName: String) -> Future<MCOIMAPFolderInfo, NSError> {
    let promise = Promise<MCOIMAPFolderInfo, NSError>()
    
    // Fetch the folder info from the server
    let operation = self.session.folderInfoOperation(folderName)
    operation.start { error, folderInfo in
      guard let info = folderInfo else {
        return promise.failure(error ?? HushError.Unknown.NSError)
      }
      
      promise.success(info)
    }
    
    return promise.future
  }
  
  func nextFetchMessagesRange(batchSize: Int, messageCount: Int) -> MCORange {
    // Update total message count on this instance
    let totalMessageCountChanged = self.totalNumberOfMessages != messageCount
    self.totalNumberOfMessages = messageCount
    
    let nextMessageCount = self.messages.count + batchSize
    
    // Figure out the range of messages to load
    var numberOfMessagesToLoad = min(self.totalNumberOfMessages, nextMessageCount)
    
    // Default to loading the last batchSize
    var fetchRange = MCORange(
      location: UInt64(self.totalNumberOfMessages - (numberOfMessagesToLoad - 1)),
      length: UInt64((numberOfMessagesToLoad - 1))
    )
    
    // .. But if nothing has changed, fetch what we don't have
    if (!totalMessageCountChanged && self.messages.count > 0) {
      numberOfMessagesToLoad -= self.messages.count
      
      fetchRange = MCORange(
        location: UInt64(self.totalNumberOfMessages - self.messages.count - (numberOfMessagesToLoad - 1)),
        length: UInt64(numberOfMessagesToLoad - 1)
      )
    }
    
    return fetchRange
  }
  
  /// Initiate the downloading of messages from the server
  func fetchMessages(batchSize: Int) -> Future<[MCOIMAPMessage], NSError> {
    let promise = Promise<[MCOIMAPMessage], NSError>()
    let folderName = "INBOX"
    
    // Fetch folder information from server
    self.fetchFolderInfo(folderName)
      .onSuccess { info in
        // Get the next uid fetch range
        let fetchRange = self.nextFetchMessagesRange(batchSize, messageCount: Int(info.messageCount))
        
        if fetchRange.length == 0 {
          return promise.success([])
        }
        
        // Create the fetch operation and start it
        self.fetchMessagesOperation = self.session.fetchMessagesByNumberOperationWithFolder(folderName,
          requestKind: self.messagesRequestKind,
          numbers: MCOIndexSet(range: fetchRange)
        )
        
        self.fetchMessagesOperation.start{ error, messages, deletedMessages in
          if let messages = messages as? [MCOIMAPMessage] {
            self.messages.extend(messages)
            promise.success(messages)
          }
          else {
            promise.failure(error ?? HushError.Unknown.NSError)
          }
        }
      }
      .onFailure { error in
        promise.failure(error)
      }
  
    return promise.future
  }
  
  /// Sets up the IMAP session connection parameters
  private func setupIMAPSession() {
    self.session.hostname = hostname
    self.session.port = UInt32(port)
    self.session.connectionType = .TLS
  }
}

protocol IMAPConnectionDelegate {
  func didReceiveMessages(connection: IMAPConnection, messages: [MCOAbstractMessage])
}