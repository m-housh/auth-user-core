//
//  Role.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import FluentSQLite

@testable import AuthUserCore


final class TRole: SQLiteModel, AnyRole, Migration {    
    
    typealias User = TUser
    
    var name: String
    var id: Int?
    
    init(id: Int? = nil, name: String) {
        self.name = name
        self.id = id
    }
    
    var users: Siblings<TRole, User, User.UserRole> {
        return siblings()
    }
    
}

final class TRoleController: AnyRoleController {
    
    typealias RoleType = Role
    
    var path: [PathComponentsRepresentable]
    var middleware: [Middleware]?
    
    init(_ path: PathComponentsRepresentable..., using middleware: [Middleware]?) {
        self.path = path
        self.middleware = middleware
    }
    
}

struct PopulateRoles: AnyPopulateRoles {
    
    typealias Database = SQLiteDatabase
    typealias Role = TRole
}

typealias Role = TRole
typealias RoleController = TRoleController
