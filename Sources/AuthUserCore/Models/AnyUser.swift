//
//  AnyUser.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import Fluent
import Authentication


public protocol AnyUser: Model, Parameter, Content where Database: JoinSupporting, ID == UUID {
    
    associatedtype Role: AnyRole where Database == Role.Database
    associatedtype UserRole: AnyUserRole where Database == UserRole.Database
    
    var id: UUID? { get set }
    var username: String { get set }
    var email: String? { get set }
    var password: String { get set }
    
    init(id: UUID?, username: String, password: String, email: String?)
    
    static func hashPassword(_ password: String) throws -> String
    
    var roles: Siblings<Self, Role, UserRole> { get }
    
    func hasRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> Future<Bool>
    
    func attachRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> Future<Self>
    
}

extension AnyUser {
    
    public static func hashPassword(_ password: String) throws -> String {
        return try BCrypt.hash(password)
    }
    
    public func hasRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> Future<Bool> {
        return try roles.query(on: conn)
            .filter(\Role.name == role.description)
            .count()
            .map { count in return count > 0 }
    }
}

extension AnyUser where Self: BasicAuthenticatable {
    
    public static var usernameKey: WritableKeyPath<Self, String> {
        return \.username
    }
    
    public static var passwordKey: WritableKeyPath<Self, String> {
        return \.password
    }
}
