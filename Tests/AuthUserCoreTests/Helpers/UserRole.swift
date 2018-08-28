//
//  TUserRole.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/18/18.
//

import Vapor
import FluentSQLite

@testable import AuthUserCore


final class TUserRole: SQLiteModel, AnyUserRole, Migration {
   
    /*
    static var leftIDKey: WritableKeyPath<TUserRole, UUID> {
        return \.userID
    }
    
    static var rightIDKey: WritableKeyPath<TUserRole, Int> {
        return \.roleID
    }*/
    
    
    typealias User = TUser
    typealias Left = TUser
    typealias Right = TUser.Role
    
    var id: Int?
    var userID: UUID
    var roleID: Int
    
    init(_ user: TUser, _ role: TRole) throws {
        self.userID = try user.requireID()
        self.roleID = try role.requireID()
    }
}

typealias UserRole = TUserRole
