//
//  PublicUser.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import Fluent

public protocol AnyPublicUser: Content {
    
    associatedtype User: AnyUser
    
    var id: User.ID? { get set }
    var username: String { get set }
    var email: String? { get set }
    var roles: [String] { get set }
    
    init(user: User, roles: [String])
    
    func user(on conn: DatabaseConnectable) throws -> Future<User>
    
    func getRoles(on conn: DatabaseConnectable) throws -> Future<[User.Role]>
    
    /*
    func hasRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> Future<Bool>
    */
}

extension AnyPublicUser where User.Database: QuerySupporting {
    
    public func user(on conn: DatabaseConnectable) throws -> Future<User> {
        return User.query(on: conn)
            .filter(\.username == self.username)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    public func getRoles(on conn: DatabaseConnectable) throws -> Future<[User.Role]> {
        return try user(on: conn).flatMap { user in
            return try user.roles.query(on: conn).all()
        }
    }
    
    /*
    public func hasRole(_ role: CustomStringConvertible, on conn: DatabaseConnectable) throws -> Future<Bool> {
        return try user(on: conn).flatMap { user in
            return try user.hasRole(role, on: conn)
        }
    }*/
}


public struct PublicUser<U>: AnyPublicUser, Content where U: AnyUser {
    
    public typealias User = U
    
    public var id: User.ID?
    public var username: String
    public var email: String?
    public var roles: [String]
    
    public init(user: User, roles: [String] = []) {
        self.id = user.id
        self.username = user.username
        self.email = user.email
        self.roles = roles
    }
    
    public static func create(user: User, on conn: DatabaseConnectable) throws -> Future<PublicUser<U>> {
        
        var user = PublicUser<U>(user: user)
        return try user.getRoles(on: conn).map { roles in
            user.roles = roles.map { $0.name }
            return user
        }
    }
}

extension PublicUser: Parameter {
   
    public typealias ResolvedParameter = User.ResolvedParameter
    
    public static func resolveParameter(_ parameter: String, on container: Container) throws -> U.ResolvedParameter {
        return try User.resolveParameter(parameter, on: container)
    }
    
}

