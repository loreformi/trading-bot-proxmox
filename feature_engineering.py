"""
Feature Engineering Module
Creates technical indicators for trading
"""
import pandas as pd
import numpy as np
from loguru import logger

class FeatureEngineer:
    def __init__(self, config_path):
        self.config_path = config_path
        
    def process_pipeline(self, df, fit=True, save=False):
        """Create all features"""
        logger.info("Creating features...")
        
        df = df.copy()
        
        # Simple Moving Averages
        df['gold_SMA_20'] = df['gold_Close'].rolling(20).mean()
        df['gold_SMA_50'] = df['gold_Close'].rolling(50).mean()
        
        # RSI
        df['gold_RSI'] = self._calculate_rsi(df['gold_Close'], 14)
        
        # ATR
        df['gold_ATR'] = self._calculate_atr(df, 14)
        
        # VIX ratio
        df['vix_change'] = df['vix_Close'].pct_change()
        
        # Drop NaN rows
        df = df.dropna()
        
        logger.info(f"Features created: {df.shape[1]} columns, {df.shape[0]} rows")
        
        if save:
            df.to_csv('data/processed/features.csv', index=False)
            
        return df
    
    def _calculate_rsi(self, prices, period=14):
        """Calculate RSI indicator"""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def _calculate_atr(self, df, period=14):
        """Calculate ATR indicator"""
        high = df['gold_High']
        low = df['gold_Low']
        close = df['gold_Close']
        
        tr1 = high - low
        tr2 = abs(high - close.shift())
        tr3 = abs(low - close.shift())
        
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        atr = tr.rolling(period).mean()
        return atr
