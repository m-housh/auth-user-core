//
//  AnyUserRole.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import Fluent


public protocol AnyUserRole: ModifiablePivot {
    
    associatedtype User: AnyUser where User.Database == Database
    //associatedtype Role: AnyRole where Role.Database == Database
    
    var id: ID? { get set }
    var userID: User.ID { get set }
    var roleID: User.Role.ID { get set }
    
}


