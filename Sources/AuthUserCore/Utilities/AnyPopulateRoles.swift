//
//  AnyPopulateRoles.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/18/18.
//

import Vapor
import Fluent


public protocol AnyPopulateRoles: Migration {
    
    associatedtype Role: AnyRole
    
    static var names: [String] { get }
}

extension AnyPopulateRoles {
    
    public static var names: [String] {
        return ["admin", "user"]
    }
    
    public static func prepare(on conn: Role.Database.Connection) -> Future<Void> {
        
        let futures = names.map { name -> EventLoopFuture<Void> in
            return Role(id: nil, name: name)
                .save(on: conn)
                .map(to: Void.self) { _ in return }
        }
        
        return Future<Void>.andAll(futures, eventLoop: conn.eventLoop)
    }
    
    public static func revert(on conn: Role.Database.Connection) -> EventLoopFuture<Void> {
        
        let futures = names.map { name -> Future<Void> in
            return Role.query(on: conn)
                .filter(\.name == name)
                .delete()
        }
        
        return Future<Void>.andAll(futures, eventLoop: conn.eventLoop)
    }
}
