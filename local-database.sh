#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found. Please create one with DATABASE_NAME, DATABASE_USER, and DB_PASSWORD."
  exit 1
fi

if [ -z "$DATABASE_NAME" ] || [ -z "$DATABASE_USER" ] || [ -z "$DATABASE_PASSWORD" ]; then
  echo "DATABASE_NAME, DATABASE_USER, and DATABASE_PASSWORD must be set in the .env file."
  exit 1
fi

ACTION=$1

PG_DATA="/usr/local/var/postgresql@15" # Adjust this path if necessary

start_db() {
  echo "Starting PostgreSQL..."
  brew services start postgresql@15
  sleep 10

  echo "Creating database and user..."
  
  if psql -lqt | cut -d \| -f 1 | grep -qw postgres; then
    psql postgres -c "CREATE USER $DATABASE_USER WITH PASSWORD '$DATABASE_PASSWORD';"
    psql postgres -c "CREATE DATABASE $DATABASE_NAME OWNER $DATABASE_USER;"
    psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;"
    echo "Database '$DATABASE_NAME' and user '$DATABASE_USER' created for development."
  else
    echo "PostgreSQL doesn't seem to be running correctly. Check your installation."
  fi
}

stop_db() {
  echo "Stopping PostgreSQL..."
  brew services stop postgresql@15
}

cleanup_db() {
  echo "Cleaning up database and user..."
  psql postgres -c "DROP DATABASE IF EXISTS $DATABASE_NAME;" || echo "Error: Failed to drop database '$DATABASE_NAME'."
  # psql postgres -c "DROP USER IF EXISTS $DATABASE_USER;" || echo "Error: Failed to drop user '$DATABASE_USER'."
  
  echo "Database '$DATABASE_NAME' has been removed."
}

case $ACTION in
  start)
    start_db
    ;;
  stop)
    stop_db
    ;;
  cleanup)
    cleanup_db
    ;;
  *)
    echo "Invalid action: $ACTION. Use start, stop, or cleanup."
    exit 1
    ;;
esac
