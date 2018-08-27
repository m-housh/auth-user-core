//
//  AnyRole.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import Fluent


public protocol AnyRole: Model, Parameter, Content where ID == Int {
    
    //associatedtype User: AnyUser where Database == User.Database
    
    var id: Int? { get set }
    var name: String { get set }
    init(id: ID?, name: String)
    
    static func findOrCreate(_ name: String, on conn: DatabaseConnectable) throws -> Future<Self>
    
    //var users: Siblings<Self, User, User.UserRole> { get }
    
}

extension AnyRole where Database: QuerySupporting {
    
    public static func findOrCreate(_ name: String, on conn: DatabaseConnectable) throws -> Future<Self> {
        return Self.query(on: conn)
            .filter(\.name == name)
            .first()
            .flatMap { weakRole in
                guard let role = weakRole else {
                    return Self.init(id: nil, name: name).save(on: conn)
                }
                return conn.future(role)
            }
    }
}
