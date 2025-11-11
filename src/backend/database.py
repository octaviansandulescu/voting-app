"""
🗄️ Database Management Module

Encapsulates all database operations.
Concept DevOPS: Separation of Concerns (DB logic separate from API)

Suporta MySQL cu PyMySQL driver
"""

import mysql.connector
from mysql.connector import Error
import logging
import os
import time

logger = logging.getLogger(__name__)


class Database:
    """MySQL Database Connection Manager"""
    
    def __init__(self):
        """Initialize database connection with retry logic"""
        self.host = os.getenv("DB_HOST", "localhost")
        self.port = int(os.getenv("DB_PORT", 3306))
        self.user = os.getenv("DB_USER", "voting_user")
        self.password = os.getenv("DB_PASSWORD", "")
        self.database = os.getenv("DB_NAME", "voting_app")
        
        # Retry logic for Docker/K8s where DB might not be ready immediately
        max_retries = 30
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                # Create connection
                self.connection = mysql.connector.connect(
                    host=self.host,
                    port=self.port,
                    user=self.user,
                    password=self.password,
                    database=self.database
                )
                
                logger.info(f"[DB] Connected to {self.host}:{self.port}/{self.database}")
                
                # Initialize tables if needed
                self._init_tables()
                break
                
            except Error as e:
                retry_count += 1
                logger.warning(f"[DB] Connection attempt {retry_count}/{max_retries} failed: {str(e)}")
                if retry_count >= max_retries:
                    logger.error(f"[DB] Failed to connect after {max_retries} attempts")
                    raise
                time.sleep(2)  # Wait 2 seconds before retry
    
    def _init_tables(self):
        """Create tables if they don't exist"""
        try:
            cursor = self.connection.cursor()
            
            # Create votes table
            create_table_query = """
            CREATE TABLE IF NOT EXISTS votes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                vote VARCHAR(10) NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_vote (vote)
            )
            """
            
            cursor.execute(create_table_query)
            self.connection.commit()
            cursor.close()
            
            logger.info("[DB] Tables initialized")
            
        except Error as e:
            logger.error(f"[DB] Table initialization failed: {str(e)}")
            raise
    
    def is_connected(self) -> bool:
        """Check if database is connected"""
        try:
            if self.connection and self.connection.is_connected():
                return True
            return False
        except:
            return False
    
    def insert_vote(self, vote: str):
        """Insert a vote into database"""
        try:
            cursor = self.connection.cursor()
            
            query = "INSERT INTO votes (vote) VALUES (%s)"
            cursor.execute(query, (vote,))
            
            self.connection.commit()
            cursor.close()
            
            logger.info(f"[DB] Vote inserted: {vote}")
            
        except Error as e:
            logger.error(f"[DB] Insert failed: {str(e)}")
            raise
    
    def get_results(self) -> dict:
        """Get vote counts grouped by vote type"""
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            query = """
            SELECT 
                vote,
                COUNT(*) as count
            FROM votes
            GROUP BY vote
            """
            
            cursor.execute(query)
            results = cursor.fetchall()
            cursor.close()
            
            # Format results
            vote_counts = {
                "dogs": 0,
                "cats": 0
            }
            
            for row in results:
                if row['vote'] in vote_counts:
                    vote_counts[row['vote']] = row['count']
            
            logger.info(f"[DB] Results: {vote_counts}")
            
            return vote_counts
            
        except Error as e:
            logger.error(f"[DB] Query failed: {str(e)}")
            raise
    
    def close(self):
        """Close database connection"""
        try:
            if self.connection and self.connection.is_connected():
                self.connection.close()
                logger.info("[DB] Connection closed")
        except Error as e:
            logger.error(f"[DB] Close failed: {str(e)}")
