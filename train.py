#!/usr/bin/env python3
"""
Training Script - Gold-VIX Trading Bot
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from loguru import logger
import yaml
from stable_baselines3 import DQN
from stable_baselines3.common.monitor import Monitor
from datetime import datetime

# Import custom modules
from data_loader import DataLoader
from feature_engineering import FeatureEngineer
from environment import GoldVIXTradingEnv

logger.add("../logs/training.log")

def main():
    logger.info("Starting Gold-VIX Trading Bot training...")
    
    config_path = '../config/config.yaml'
    
    # Load data
    logger.info("Loading data...")
    loader = DataLoader(config_path)
    df = loader.download_data(save_raw=True)
    
    # Engineer features
    logger.info("Engineering features...")
    engineer = FeatureEngineer(config_path)
    df_processed = engineer.process_pipeline(df, fit=True, save=True)
    
    # Split data
    train_size = int(len(df_processed) * 0.7)
    train_data = df_processed[:train_size]
    
    # Create environment
    logger.info("Creating training environment...")
    train_env = GoldVIXTradingEnv(train_data, config_path)
    train_env = Monitor(train_env)
    
    # Train model
    logger.info("Training DQN model...")
    model = DQN('MlpPolicy', train_env, 
                learning_rate=0.0001,
                buffer_size=50000,
                batch_size=64,
                gamma=0.99,
                verbose=1,
                tensorboard_log='../logs/tensorboard')
    
    model.learn(total_timesteps=100000)
    
    # Save model
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    model_path = f"../data/models/dqn_gold_vix_{timestamp}"
    model.save(model_path)
    
    logger.info(f"Training complete! Model saved to {model_path}")

if __name__ == "__main__":
    main()
