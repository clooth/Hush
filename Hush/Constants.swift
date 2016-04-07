//
//  Constants.swift
//  Hush
//
//  Created by Nico Hämäläinen on 09/03/16.
//  Copyright © 2016 sizeof.io. All rights reserved.
//

import Foundation

let HushErrorDomain = "io.sizeof.hush.error"

enum HushError: Int {
  case Unknown
}

extension HushError {
  /// Get the error object for this specific error type
  var NSError: Foundation.NSError {
    return Foundation.NSError(domain: HushErrorDomain, code: self.rawValue, userInfo: nil)
  }
}