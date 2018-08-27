//
//  TestTypes.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import FluentSQLite
import Authentication

@testable import AuthUserCore


final class TUser: SQLiteUUIDModel, AnyUser, Migration, BasicAuthenticatable, PasswordAuthenticatable {
    
    typealias Role = TRole
    typealias UserRole = TUserRole
    
    var id: UUID?
    var username: String
    var email: String?
    var password: String
    
    init(id: UUID? = nil, username: String, password: String, email: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.password = password
    }
    
    var roles: Siblings<TUser, TRole, TUserRole> {
        return siblings()
    }
    
    func attachRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> EventLoopFuture<TUser> {
        
        return try hasRole(role, on: conn).flatMap { hasRole in
            if hasRole == false {
                return try Role.findOrCreate(role.description, on: conn).flatMap { role in
                    return self.roles.attach(role, on: conn)
                }
                .transform(to: self)
            }
            return conn.future(self)
        }
    }

}

final class TUserController: AnyUserController {
    
    
    typealias User = TUser
    
    var path: [PathComponentsRepresentable]
    var middleware: [Middleware]?
    
    init(_ path: PathComponentsRepresentable..., using middleware: [Middleware]? = nil) {
        self.path = path
        self.middleware = middleware
    }
    
    /*
    func attachRole(_ role: TRole, to user: TUser, on conn: DatabaseConnectable) -> EventLoopFuture<TUser> {
        return user.roles.attach(role, on: conn).transform(to: user)
    }*/
    
    
}



typealias User = TUser
typealias UserController = TUserController
