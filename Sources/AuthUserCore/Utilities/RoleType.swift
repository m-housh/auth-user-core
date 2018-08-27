//
//  RoleType.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/18/18.
//

import Fluent
import Vapor

public enum RoleType {
    case id(Int)
    case named(String)
    case admin
    case user
}

extension RoleType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .id(let id):
            return String(id)
        case .named(let name):
            return name
        case .admin:
            return "admin"
        case.user:
            return "user"
        }
    }
}
