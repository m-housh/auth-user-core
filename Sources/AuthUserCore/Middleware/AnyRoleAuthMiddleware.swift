//
//  RoleAuthMiddleware.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/20/18.
//

import Vapor
import Authentication


public enum Roles {
    case any([RoleType])
    case all([RoleType])
}


public protocol AnyRoleAuthMiddleware: Middleware {
    
    associatedtype User: AnyUser where User: Authenticatable
    
    var roles: Roles { get }
    
    init(_ roles: Roles)
    
}

extension AnyRoleAuthMiddleware {
    
    private func _any(user: User, roles: [RoleType], on conn: DatabaseConnectable) throws -> Future<Bool> {
        
        return try user.roles.query(on: conn).all().map { userRoles in
            for role in roles {
                if userRoles
                    .filter({ $0.name == role.description })
                    .count > 0 {
                    return true
                }
            }
            return false
        }
    }
    
    private func _all(user: User, roles: [RoleType], on conn: DatabaseConnectable) throws -> Future<Bool> {
        
        return try user.roles.query(on: conn).all().map { userRoles in
            var hasRoles = [Bool]()
            for role in roles {
                if userRoles
                    .filter({ $0.name == role.description })
                    .count > 0 {
                    hasRoles.append(true)
                }
            }
            return hasRoles.count == roles.count
        }
    }
    
    /// See `Middleware`
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let user = try request.requireAuthenticated(User.self)
        
        switch roles {
        case .any(let roles):
            return try _any(user: user, roles: roles, on: request).flatMap { authenticated in
                if authenticated {
                    return try next.respond(to: request)
                }
                throw Abort(.unauthorized)
            }
        case .all(let roles):
            return try _all(user: user, roles: roles, on: request).flatMap { authenticated in
                if authenticated {
                    return try next.respond(to: request)
                }
                throw Abort(.unauthorized)
            }
        }
    }
}

public struct RoleAuthMiddleware<U>: AnyRoleAuthMiddleware where U: AnyUser & Authenticatable {
    
    public typealias User = U
    
    public let roles: Roles
    
    public init(_ roles: Roles) {
        self.roles = roles
    }
}

extension AnyUser where Self: Authenticatable {
    
    public static func roleAuthMiddleware(roles: Roles) -> RoleAuthMiddleware<Self> {
        return RoleAuthMiddleware<Self>(roles)
    }
    
    public static func roleAuthMiddleware(_ roles: RoleType...) -> RoleAuthMiddleware<Self> {
        return RoleAuthMiddleware<Self>(.any(roles))
    }
}
