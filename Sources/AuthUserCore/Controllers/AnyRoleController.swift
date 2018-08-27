//
//  AnyRoleController.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import SimpleController


public protocol AnyRoleController: RouteCollection {
    
    associatedtype RoleType: AnyRole where RoleType.ResolvedParameter == Future<RoleType>
    
    var collection: ModelRouteCollection<RoleType> { get }
    var path: [PathComponentsRepresentable] { get }
    var middleware: [Middleware]? { get }
    
    init(_ path: PathComponentsRepresentable..., using middleware: [Middleware]?)
}

extension AnyRoleController {
    
    var collection: ModelRouteCollection<RoleType> {
        return ModelRouteCollection(RoleType.self, path: path, using: middleware)
    }
    
    func boot(router: Router) throws {
        try collection.boot(router: router)
        
        let grouped = router.grouped(middleware ?? [])
        grouped.post(path, "findOrCreate", use: findOrCreate)
        
        
    }
}

/// Handlers
extension AnyRoleController {
    
    func findOrCreate(_ request: Request) throws -> Future<RoleType> {
        return try request.content.decode(RoleType.self).flatMap { role in
            return try RoleType.findOrCreate(role.name, on: request)
        }
    }
}
