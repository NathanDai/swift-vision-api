import Vapor

func routes(_ app: Application) throws {
    // 根路由重定向到 index.html
    app.get { req in
        req.redirect(to: "/index.html")
    }
    
    try app.register(collection: VisionController())
}
