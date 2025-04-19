import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // 设置最大请求大小为 10MB
    app.routes.defaultMaxBodySize = "10mb"
    
    // 配置静态文件服务
    let publicDirectory = app.directory.publicDirectory
    app.middleware.use(FileMiddleware(publicDirectory: publicDirectory))

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080
    
    // register routes
    try routes(app)
}
