//
//  UserTests.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import XCTest
import Vapor


@testable import AuthUserCore


final class UserTests: VaporTestCase {
    
    let path = "/user"
    
    func testCreate() {
        perform {
            let resp = try createUser()
            XCTAssertEqual(resp.username, username)
            XCTAssertEqual(resp.email, email)
            XCTAssertEqual(resp.roles, ["user"])

        }
    }
    
    func testGet() {
        perform {
            _ = try createUser()
            let users = try getAllUsers()
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0].username, username)
            XCTAssertEqual(users[0].email, email)
            XCTAssertEqual(users[0].roles, [])
        }
    }
    
    func testGetID() {
        perform {
            _ = try createUser()
            let id = try userID()
            let path = "\(self.path)/\(id)"
                
            let resp = try self.app.getResponse(to: path, decodeTo: PublicUser<User>.self)
            XCTAssertEqual(resp.username, self.username)
            XCTAssertEqual(resp.email, self.email)
        }
    }
    
    func testUpdate() {
        perform {
            var user = try createUser()
            user.username = "updated"
            let id = try userID()
            let path = "\(self.path)/\(id)"
            let resp = try app.getResponse(
                to: path,
                method: .PUT,
                headers: .init(),
                data: user,
                decodeTo: PublicUser<User>.self
            )
            
            XCTAssert(resp.username == "updated")
        }
    }
    
    func testAddRole() {
        perform {
            let admin = try createAdminUser()
            XCTAssert(admin.roles.contains("admin"))
        }
    }
    
    func testAddManyRoles() {
        perform {
            let user = try createUser(User(username: "test", password: "test"))
            XCTAssertEqual(user.roles, ["user"])
            
            let roles = RoleContext(roles: ["custom1", "custom2"])
            let path = "/user/\(user.id!)/addRole"
            
            let resp = try app.getResponse(
                to: path,
                method: .POST,
                headers: .init(),
                data: roles,
                decodeTo: PublicUser<User>.self
            )
            
            XCTAssertEqual(resp.username, user.username)
            XCTAssertEqual(resp.roles, ["user", "custom1", "custom2"])
        }
    }
    
    static let allTests = [
        ("testCreate", testCreate),
        ("testGet", testGet),
        ("testGetID", testGetID),
        ("testUpdate", testUpdate),
        ("testAddRole", testAddRole),
        ("testAddManyRoles", testAddManyRoles)
    ]
}


extension VaporTestCase {
    
    func createUser(_ user: User? = nil) throws -> PublicUser<User> {
        let user = user ?? User(username: username, password: password, email: email)
        let path = "/user"
        return try app.getResponse(
            to: path,
            method: .POST,
            headers: .init(),
            data: user,
            decodeTo: PublicUser<User>.self
        )
    }
    
    func getAllUsers() throws -> [PublicUser<User>] {
        return try app.getResponse(
            to: "/user",
            decodeTo: [PublicUser<User>].self
        )
    }
    
    func userID() throws -> User.ID {
        let path = "/test/user"
        let users = try app.getResponse(to: path, decodeTo: [User].self)
        let user = users.first { $0.username == self.username }
        guard let strongUser = user else { throw Abort(.notFound) }
        return try strongUser.requireID()
        
    }
}
