"""
Data Loader Module - Trading Bot
Downloads and prepares market data
"""
import pandas as pd
import yfinance as yf
from loguru import logger

class DataLoader:
    def __init__(self, config_path):
        self.config_path = config_path
        
    def download_data(self, save_raw=False):
        """Download gold and VIX data from Yahoo Finance"""
        logger.info("Downloading market data...")
        
        # Download Gold futures (GC=F) and VIX (^VIX)
        gold = yf.download("GC=F", start="2020-01-01", end="2024-12-31", interval="1d")
        vix = yf.download("^VIX", start="2020-01-01", end="2024-12-31", interval="1d")
        
        # Combine data
        df = pd.DataFrame({
            'datetime': gold.index,
            'gold_Open': gold['Open'].values,
            'gold_High': gold['High'].values,
            'gold_Low': gold['Low'].values,
            'gold_Close': gold['Close'].values,
            'gold_Volume': gold['Volume'].values,
            'vix_Close': vix['Close'].values
        })
        
        df = df.dropna()
        logger.info(f"Downloaded {len(df)} rows of data")
        
        if save_raw:
            df.to_csv('data/raw/market_data.csv', index=False)
            logger.info("Data saved to data/raw/")
            
        return df
