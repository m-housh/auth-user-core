//
//  VaporTestCase.swift
//  AuthUser3Tests
//
//  Created by Michael Housh on 8/16/18.
//

import Vapor
import XCTest
import VaporTestable
import Authentication
import FluentSQLite
import SimpleController

@testable import AuthUserCore

class VaporTestCase: XCTestCase, VaporTestable {
    
    var app: Application!
    
    let username = "test"
    let password = "password"
    let email = "test@test.com"
    let role = "test"

    override func setUp() {
        perform {
            app = try! makeApplication()
        }
    }
    
    override func tearDown() {
        perform {
            try self.revert()
        }
    }
}

extension VaporTestCase {
    
    private func repeatAuthenticated(_ request: Request) throws -> Future<PublicUser<User>> {
        let user =  try request.requireAuthenticated(User.self)
        return try PublicUser.create(user: user, on: request)
    }
    
    // See `VaporTestable`.
    func routes(_ router: Router) throws {
        let roleController = RoleController("user", "role", using: [])
        try router.register(collection: roleController)
        
        /// This controller returns public users
        let userController = UserController("user", using: [])
        try router.register(collection: userController)
        
        /// This controller is here to have access to non-public
        /// users for testing purposes.
        let testUsers = ModelRouteCollection(User.self, path: "/test/user", using: [])
        try router.register(collection: testUsers)
    
        /// This controller requires the `user` role to access.
        let userGroup = router.grouped(
            User.basicAuthMiddleware(using: BCrypt),
            User.roleAuthMiddleware(.user),
            User.guardAuthMiddleware()
        )
        userGroup.get("userOnly", use: repeatAuthenticated)
        
        /// This controller requires the `user` or `admin role to access.
        let adminOrUserGroup = router.grouped(
            User.basicAuthMiddleware(using: BCrypt),
            User.roleAuthMiddleware(roles: .any([.admin, .user])),
            User.guardAuthMiddleware()
        )
        adminOrUserGroup.get("adminOrUser", use: repeatAuthenticated)
    
        
        let customGroup = router.grouped(
            User.basicAuthMiddleware(using: BCrypt),
            User.roleAuthMiddleware(roles:
                .all([.user, .named("custom")])
            ),
            User.guardAuthMiddleware()
        )
        
        customGroup.get("customAndUser", use: repeatAuthenticated)

    }

    // See `VaporTestable`.
    func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
        try services.register(FluentSQLiteProvider())
        try services.register(AuthenticationProvider())
        
        /// Register routes to the router
        let router = EngineRouter.default()
        try routes(router)
        services.register(router, as: Router.self)
        
        /// Register middleware
        var middlewares = MiddlewareConfig() // Create _empty_ middleware config
        middlewares.use(SessionsMiddleware.self) // for using sessions
        services.register(middlewares)
        
        /// Database
        let sqlite = try SQLiteDatabase(storage: .memory)
        /// Register the configured SQLite database to the database config.
        var databases = DatabasesConfig()
        databases.add(database: sqlite, as: .sqlite)
        services.register(databases)
        
        /// Configure migrations
        var migrations = MigrationConfig()
        migrations.add(model: User.self, database: .sqlite)
        migrations.add(model: Role.self, database: .sqlite)
        migrations.add(migration: PopulateRoles.self, database: .sqlite)
        migrations.add(model: UserRole.self, database: .sqlite)
        //migrations.add(model: TestUserRole.self, database: .sqlite)
        //migrations.add(model: TestAuthUser.self, database: .sqlite)
        
        services.register(migrations)
        
        /// Command configuration
        var commandConfig = CommandConfig.default()
        commandConfig.useFluentCommands()
        //commandConfig.use(TestRoleCommand(), as: "role")
        services.register(commandConfig)
        
        config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
        
    }
}

