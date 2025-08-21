#!/bin/bash
# quick-deploy.sh - Get C47 PWA live in under 1 week

echo "🚀 C47 PWA Quick Deployment Pipeline"
echo "======================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 completed successfully${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Day 1-2: Setup and Build
echo -e "\n${YELLOW}Day 1-2: Setup and Build${NC}"
echo "----------------------------------------"

# Check if C43 repo exists, clone if not
if [ ! -d "../c43" ]; then
    echo "Cloning C43 repository..."
    git clone https://gitlab.com/rpncalculators/c43.git ../c43
    check_status "Repository clone"
else
    echo "C43 repository already exists, skipping clone"
fi

# Build with Broadway backend
cd ../c43/ || exit 1
export GDK_BACKEND=broadway
echo "Building C47 with Broadway backend..."
make clean && make
check_status "Broadway build"

# Day 3: Containerize Broadway backend
echo -e "\n${YELLOW}Day 3: Containerize Broadway Backend${NC}"
echo "----------------------------------------"

cd ../c47-pwa/ || exit 1

# Create Dockerfile for Broadway backend
cat > docker/Dockerfile.broadway << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libgtk-3-bin \
    gtk-3-examples \
    libglib2.0-0 \
    xvfb \
    x11vnc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY c47-simulator /app/
COPY start-broadway.sh /app/
COPY assets/gtk/ /app/assets/

RUN chmod +x /app/start-broadway.sh /app/c47-simulator

EXPOSE 8080

CMD ["./start-broadway.sh"]
EOF

# Create Broadway startup script
cat > docker/start-broadway.sh << 'EOF'
#!/bin/bash
# Start virtual display for headless Broadway
Xvfb :99 -screen 0 800x600x16 &
export DISPLAY=:99

# Start Broadway server
broadwayd :5 &
sleep 3

# Launch original C47 GTK simulator
export GDK_BACKEND=broadway
export BROADWAY_DISPLAY=:5
./c47-simulator
EOF

chmod +x docker/start-broadway.sh

# Build Broadway backend container
echo "Building Broadway backend Docker image..."
docker build -f docker/Dockerfile.broadway -t c47-pwa-backend .
check_status "Backend Docker build"

# Start Broadway backend
echo "Starting Broadway backend container..."
docker run -d -p 8080:8080 --name c47-backend c47-pwa-backend
check_status "Backend container start"

# Day 4: Deploy PWA frontend
echo -e "\n${YELLOW}Day 4: Deploy PWA Frontend${NC}"
echo "----------------------------------------"

# Copy GTK assets
echo "Copying GTK assets..."
if [ -d "../c43/ui/" ]; then
    cp -r ../c43/ui/ ./public/assets/gtk/
fi
if [ -d "../c43/icons/" ]; then
    cp -r ../c43/icons/ ./public/assets/gtk/
fi
check_status "Asset copy"

# Create frontend Dockerfile
cat > docker/Dockerfile.frontend << 'EOF'
FROM nginx:alpine

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY public/ /usr/share/nginx/html/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
EOF

# Build frontend container
echo "Building PWA frontend Docker image..."
docker build -f docker/Dockerfile.frontend -t c47-pwa-frontend .
check_status "Frontend Docker build"

# Day 5: Production deployment
echo -e "\n${YELLOW}Day 5: Production Deployment${NC}"
echo "----------------------------------------"

# Create docker-compose file
cat > docker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  c47-broadway:
    image: c47-pwa-backend
    container_name: c47-backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - DISPLAY=:99
      - GDK_BACKEND=broadway
      - BROADWAY_DISPLAY=:5
    volumes:
      - ./assets/gtk:/app/assets:ro
    networks:
      - c47-network

  c47-frontend:
    image: c47-pwa-frontend
    container_name: c47-frontend
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - c47-broadway
    networks:
      - c47-network

networks:
  c47-network:
    driver: bridge
EOF

# Deploy with docker-compose
echo "Starting production deployment..."
cd docker && docker-compose up -d
check_status "Production deployment"

# Day 6-7: Testing and optimization
echo -e "\n${YELLOW}Day 6-7: Testing and Optimization${NC}"
echo "----------------------------------------"

# Test PWA quality
if [ -f "../tests/test-pwa-quality.sh" ]; then
    echo "Running PWA quality tests..."
    ../tests/test-pwa-quality.sh
fi

# Test mobile compatibility
if [ -f "../tests/test-mobile-compatibility.sh" ]; then
    echo "Running mobile compatibility tests..."
    ../tests/test-mobile-compatibility.sh
fi

echo -e "\n${GREEN}✅ C47 PWA deployed successfully!${NC}"
echo "======================================"
echo "📱 Installation Instructions:"
echo "  iOS: Safari > Share > Add to Home Screen"
echo "  Android: Chrome > Menu > Add to Home Screen"
echo "  Desktop: Chrome > Install App icon in address bar"
echo ""
echo "🌐 Available at: http://localhost"
echo "   Broadway backend: http://localhost:8080"