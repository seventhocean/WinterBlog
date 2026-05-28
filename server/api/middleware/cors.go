package middleware

import (
	"flec_blog/config"

	"github.com/gin-gonic/gin"
)

// CORS 跨域中间件
func CORS(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// 检查白名单
		allowed := false
		wildcard := false
		for _, allowOrigin := range cfg.Server.AllowOrigins {
			if allowOrigin == "*" {
				wildcard = true
				allowed = true
				break
			}
			if allowOrigin == origin {
				allowed = true
				break
			}
		}
		if !allowed && origin != "" {
			c.AbortWithStatus(403)
			return
		}

		if !allowed {
			// 无 Origin 的请求（如静态文件直链访问）不设置 CORS header
			c.Next()
			return
		}

		// wildcard + 无 origin：设 *，不设 credentials
		// wildcard + 有 origin 或精确匹配：设具体 origin，允许 credentials
		if wildcard && origin == "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		} else {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		}
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "X-Scene")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
