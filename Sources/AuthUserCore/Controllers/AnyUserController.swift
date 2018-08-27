//
//  AnyUserController.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import Fluent
import SimpleController


public struct RoleContext: Content {
    public let role: String?
    public let roles: [String]?
    
    public init(role: String) {
        self.role = role
        self.roles = nil
    }
    
    public init(roles: [String]) {
        self.role = nil
        self.roles = roles
    }
    
    public func allRoles() -> [String] {
        var roles = self.roles ?? []
        if let role = self.role {
            roles.append(role)
        }
        return roles
    }
}


public protocol AnyUserController: RouteCollection {
    
    associatedtype User: AnyUser where User.ResolvedParameter == Future<User>
    
    typealias PublicUserType = PublicUser<User>
    
    var collection: ModelRouteCollection<User> { get }
    var path: [PathComponentsRepresentable] { get }
    var middleware: [Middleware]? { get }
    
    init(_ path: PathComponentsRepresentable..., using middleware: [Middleware]?)
    
}

extension AnyUserController {
    
    public var collection: ModelRouteCollection<User> {
        return ModelRouteCollection(User.self, path: path, using: middleware)
    }
    
    public func boot(router: Router) throws {
        
        let grouped = router.grouped(middleware ?? [])
        grouped.post(path, use: createHandler)
        grouped.put(path, PublicUser<User>.parameter, use: updateHandler)
        grouped.get(path, User.parameter, use: getByIDHandler)
        grouped.get(path, use: getHandler)
        grouped.delete(path, User.parameter, use: collection.deleteHandler)
        grouped.post(path, User.parameter, "addRole", use: addRoleHandler)
        
    }
}

/// Handlers
extension AnyUserController {
    
    private func saveUser(_ request: Request) throws -> Future<User> {
        return try request.content.decode(User.self).flatMap { u in
            var user = u
            user.password = try User.hashPassword(user.password)
            return user.save(on: request)
        }
    }
    
    private func addRoles(_ roles: [CustomStringConvertible] = [], to user: User, on request: Request) throws -> Future<User> {
        var roles = roles
        
        if roles.count == 0 {
            roles = [RoleType.user]
        }
            
        let futures = try roles.map { role in
            return try user.attachRole(role, on: request)
                .map(to: Void.self) { _ in return }
        }
            
        return Future<Void>
            .andAll(futures, eventLoop: request.eventLoop)
            .transform(to: user)
    }
    
    func createHandler(_ request: Request) throws -> Future<PublicUser<User>> {
        return try saveUser(request).flatMap { user in
            return try self.addRoles(to: user, on: request)
                .public(on: request)
        }
    }
    
    func getHandler(_ request: Request) throws -> Future<[PublicUserType]> {
        return try collection.getHandler(request).map { users in
            return users.public()
        }
    }
    
    func getByIDHandler(_ request: Request) throws -> Future<PublicUserType> {
        return try collection.getByIdHandler(request).public()
    }
    
    func updateHandler(_ request: Request) throws -> Future<PublicUserType> {
        return try request.parameters.next(PublicUser<User>.self).flatMap { user in
            var user = user
            return try request.content.decode(PublicUserType.self).flatMap { publicUser in
                user.username = publicUser.username
                if let email = publicUser.email {
                    user.email = email
                }
                return user.update(on: request).public(on: request)
            }
            
        }
    }
    
    func addRoleHandler(_ request: Request) throws -> Future<PublicUserType> {
        return try request.parameters.next(User.self).flatMap { user in
            return try request.content.decode(RoleContext.self).flatMap { ctx in
                return try self.addRoles(ctx.allRoles(), to: user, on: request)
                    .public(on: request)
            }
        }
    }
}

extension Future where T: AnyUser {
    
    func `public`(on conn: DatabaseConnectable? = nil) -> Future<PublicUser<T>> {
        if let conn = conn {
            return self.flatMap { user in
                return try PublicUser<T>.create(user: user, on: conn)
            }
        }
        
        return self.map { user in
            return PublicUser<T>(user: user)
        }
    }
}

extension Array where Element: AnyUser {
    
    func `public`() -> [PublicUser<Element>] {
        return self.map { user in
            return PublicUser<Element>(user: user)
        }
    }
}
