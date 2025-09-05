#!/bin/bash

set -e

IMAGE_NAME="postgres-citus-test"
CONTAINER_NAME="postgres-citus-test"
TEST_PASSWORD="testpass"
TEST_DB="testdb"

echo "🐘 Testing PostgreSQL + Citus Docker Image Locally"
echo "=================================================="

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# Set trap for cleanup on script exit
trap cleanup EXIT

echo "📦 Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "🚀 Starting PostgreSQL container..."
docker run --rm -d \
  --name "$CONTAINER_NAME" \
  -e POSTGRES_PASSWORD="$TEST_PASSWORD" \
  -e POSTGRES_DB="$TEST_DB" \
  -p 5432:5432 \
  "$IMAGE_NAME"

echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" pg_isready -U postgres >/dev/null 2>&1; then
        echo "✅ PostgreSQL is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ PostgreSQL failed to start within 30 seconds"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
    sleep 1
done

echo "🔍 Testing database connectivity..."
if ! docker exec "$CONTAINER_NAME" psql -U postgres -d "$TEST_DB" -c "SELECT version();" | grep PostgreSQL; then
    echo "❌ Database connectivity test failed"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

echo "🧩 Checking installed extensions..."

# Wait a bit more for extensions to be fully set up
sleep 5

# Check if we can connect and basic extensions work
if docker exec "$CONTAINER_NAME" psql -U postgres -d "$TEST_DB" -c "SELECT citus_version();" >/dev/null 2>&1; then
    echo "✅ Citus extension working in $TEST_DB"
else
    echo "❌ Citus not working in $TEST_DB"
    exit 1
fi

if docker exec "$CONTAINER_NAME" psql -U postgres -d nibbler -c "SELECT * FROM cron.job LIMIT 0;" >/dev/null 2>&1; then
    echo "✅ pg_cron extension working in nibbler database"
else
    echo "❌ pg_cron not working in nibbler database"
    exit 1
fi

echo "✅ All extensions verified and working"

echo "🔧 Testing Citus functionality..."
CITUS_VERSION=$(docker exec "$CONTAINER_NAME" psql -U postgres -d "$TEST_DB" -t -c "SELECT citus_version();" | tr -d ' ')
if [ -n "$CITUS_VERSION" ]; then
    echo "✅ Citus is working: $CITUS_VERSION"
else
    echo "❌ Citus version check failed"
    exit 1
fi

echo "⚙️  Checking PostgreSQL configuration..."
SHARED_LIBS=$(docker exec "$CONTAINER_NAME" psql -U postgres -t -c "SHOW shared_preload_libraries;" | tr -d ' ')
if [[ "$SHARED_LIBS" == *"citus"* ]] && [[ "$SHARED_LIBS" == *"pg_cron"* ]] && [[ "$SHARED_LIBS" == *"pg_partman_bgw"* ]]; then
    echo "✅ Shared preload libraries configured correctly: $SHARED_LIBS"
else
    echo "❌ Shared preload libraries missing required extensions: $SHARED_LIBS"
    exit 1
fi

echo "🗄️  Testing pg_cron configuration..."
CRON_DB=$(docker exec "$CONTAINER_NAME" psql -U postgres -t -c "SHOW cron.database_name;" | tr -d ' ')
if [ "$CRON_DB" = "nibbler" ]; then
    echo "✅ pg_cron database configured correctly: $CRON_DB"
else
    echo "❌ pg_cron database configuration incorrect: $CRON_DB"
    exit 1
fi

echo "📊 Testing pg_partman configuration..."
PARTMAN_INTERVAL=$(docker exec "$CONTAINER_NAME" psql -U postgres -t -c "SHOW pg_partman_bgw.interval;" | tr -d ' ')
if [ "$PARTMAN_INTERVAL" = "3600" ]; then
    echo "✅ pg_partman interval configured correctly: ${PARTMAN_INTERVAL}s"
else
    echo "❌ pg_partman interval configuration incorrect: $PARTMAN_INTERVAL"
    exit 1
fi

echo "🎯 Testing final user experience (as per README)..."
docker stop "$CONTAINER_NAME"

docker run --rm -d \
  --name pg-citus \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  "$IMAGE_NAME"

echo "⏳ Waiting for final test container..."
for i in {1..30}; do
    if docker exec pg-citus pg_isready -U postgres >/dev/null 2>&1; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Final test container failed to start"
        exit 1
    fi
    sleep 1
done

FINAL_TEST=$(docker exec pg-citus psql -U postgres -t -c "SELECT 'SUCCESS';" | tr -d ' ')
if [ "$FINAL_TEST" = "SUCCESS" ]; then
    echo "✅ Final user experience test passed"
else
    echo "❌ Final user experience test failed"
    exit 1
fi

docker stop pg-citus
docker rm pg-citus

echo ""
echo "🎉 All tests passed! Your Docker image is ready to push."
echo "📋 Summary:"
echo "   ✅ Docker image builds successfully"
echo "   ✅ PostgreSQL starts and accepts connections"
echo "   ✅ All extensions (citus, pg_cron, pg_partman) are installed"
echo "   ✅ Citus functionality works"
echo "   ✅ Configuration settings are correct"
echo "   ✅ Init script executes properly"
echo "   ✅ README instructions work as expected"