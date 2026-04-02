# Multi-stage build for AdCP Server
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Clone AdCP repository
RUN apk add --no-cache git && \
    git clone https://github.com/adcontextprotocol/adcp.git . && \
    cd server && \
    npm ci --only=production && \
    npm run build

# Production image
FROM node:20-alpine

# Install production dependencies
RUN apk add --no-cache \
    postgresql-client \
    curl

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/server/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/server/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/server/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/static ./static

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start server
CMD ["node", "dist/index.js"]
