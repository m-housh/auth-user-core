//
//  RoleTests.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import XCTest
import Vapor

@testable import AuthUserCore


final class RoleTests: VaporTestCase {
    
    let path = "/user/role"
    
    private func findOrCreate(_ role: Role) throws -> Role {
        let path = "\(self.path)/findOrCreate"
        
        return try app.getResponse(
            to: path,
            method: .POST,
            headers: .init(),
            data: role,
            decodeTo: Role.self
        )
    }
    
    func testCreateRole() {
        let role = Role(name: "create")
        
        perform {
            let resp = try app.getResponse(
                to: path,
                method: .POST,
                headers: .init(),
                data: role,
                decodeTo: Role.self
            )
            
            XCTAssertEqual(resp.name, role.name)
            XCTAssertNotNil(resp.id)
        }
    }
    
    func testFindOrCreate() {
        let role = Role(name: "foo")
        
        perform {
            let resp = try findOrCreate(role)
            
            XCTAssertEqual(resp.name, role.name)
            XCTAssertNotNil(resp.id)
            
            let resp2 = try findOrCreate(role)
            XCTAssertEqual(resp2.name, role.name)
            XCTAssertNotNil(resp2.id)
            XCTAssertEqual(resp.id, resp2.id)
            
        }
    }
    
    static let allTests = [
        ("testCreateRole", testCreateRole),
        ("testFindOrCreate", testFindOrCreate)
    ]
}
