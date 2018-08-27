//
//  RoleAuthTests.swift
//  AuthUser3
//
//  Created by Michael Housh on 8/21/18.
//

import XCTest
import Vapor
import Authentication


@testable import AuthUserCore

enum AuthHeaderType {
    case user
    case admin
}

final class RoleAuthTests: VaporTestCase {
    
    func testUserOnly() {
         let path = "/userOnly"
        
        perform {
            let user = try createUser()
            let resp = try app.getResponse(
                to: path,
                method: .GET,
                headers: basicAuthHeaders(),
                decodeTo: PublicUser<User>.self
            )
            
            XCTAssertEqual(resp.username, user.username)
            XCTAssert(resp.roles.contains("user"))
        }
    }
    
    func testUserOnlyFails() {
        perform {
            _ = try createUser()
            let path = "/userOnly"
            
            XCTAssertThrowsError(try app.getResponse(
                to: path,
                method: .GET,
                headers: .init(),
                decodeTo: PublicUser<User>.self)
            )
        }
    }
    
    func testAdminOrUser() {
        let path = "/adminOrUser"
        
        perform {
            let user = try createUser()
            let admin = try createAdminUser()
            
            var resp = try app.getResponse(
                to: path,
                headers: basicAuthHeaders(.user),
                decodeTo: PublicUser<User>.self
            )
            XCTAssertEqual(resp.username, user.username)
            XCTAssert(resp.roles.contains("user"))
            
            resp = try app.getResponse(
                to: path,
                headers: basicAuthHeaders(.admin),
                decodeTo: PublicUser<User>.self
            )
            XCTAssertEqual(resp.username, admin.username)
            XCTAssert(resp.roles.contains("admin"))
        }
    }
    
    func testCustomAndUser() {
        perform {
            let path = "/customAndUser"
            let user = try createUser()
            _ = try addRole("custom", to: user)
            
            let resp = try app.getResponse(
                to: path,
                method: .GET,
                headers: basicAuthHeaders(),
                decodeTo: PublicUser<User>.self
            )
            
            XCTAssertEqual(resp.username, user.username)
            XCTAssert(resp.roles.contains("custom"))
            XCTAssert(resp.roles.contains("user"))

        }
    }
    
    func testCustomAndUserFails() {
        perform {
            let path = "customAndUser"
            let user = try createUser()
            
            XCTAssertFalse(user.roles.contains("custom"))
            
            XCTAssertThrowsError(try app.getResponse(
                to: path,
                method: .GET,
                headers: basicAuthHeaders(),
                decodeTo: PublicUser<User>.self
            ))
            
        }
    }
    
    static let allTests = [
        ("testUserOnly", testUserOnly),
        ("testUserOnlyFails", testUserOnlyFails),
        ("testAdminOrUser", testAdminOrUser),
        ("testCustomAndUser", testCustomAndUser),
        ("testCustomAndUserFails", testCustomAndUserFails)
    ]
}

extension VaporTestCase {
    
    var adminUsername: String {
        return "admin"
    }
    
    var adminPassword: String {
        return "secret"
    }
    
    func basicAuthHeaders(_ type: AuthHeaderType = .user) -> HTTPHeaders {
        var headers = HTTPHeaders()
        var username: String
        var password: String
        switch type {
        case .admin:
            username = adminUsername
            password = adminPassword
        case .user:
            username = self.username
            password = self.password
        }
        
        headers.basicAuthorization = BasicAuthorization(username: username, password: password)
        return headers
    }
    
    private func addAdminRole(to user: PublicUser<User>) throws -> PublicUser<User> {
        return try addRole(RoleType.admin, to: user)
    }
    
    func getAdminID() throws -> User.ID {
        let path = "/test/user"
        let users = try app.getResponse(to: path, decodeTo: [User].self)
        let admin = users.first { $0.username == self.adminUsername }
        guard let strongAdmin = admin else { throw Abort(.notFound) }
        return try strongAdmin.requireID()
    }
    
    func createAdminUser() throws -> PublicUser<User> {
        let adminUser = User(username: adminUsername, password: adminPassword)
        let user = try createUser(adminUser)
        return try addAdminRole(to: user)
    }
    
    func addRole(_ role: CustomStringConvertible, to user: PublicUser<User>) throws -> PublicUser<User> {
        guard let id = user.id else {
            throw Abort(.badRequest)
        }
        
        let path = "/user/\(id)/addRole"
        let ctx = RoleContext(role: role.description)
        
        return try app.getResponse(
            to: path,
            method: .POST,
            headers: .init(),
            data: ctx,
            decodeTo: PublicUser<User>.self
        )
    }
}
