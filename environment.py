"""
Trading Environment for Reinforcement Learning
"""
import gym
from gym import spaces
import numpy as np
import pandas as pd
from loguru import logger

class GoldVIXTradingEnv(gym.Env):
    """Custom Trading Environment"""
    
    def __init__(self, df, config_path):
        super().__init__()
        
        self.df = df.reset_index(drop=True)
        self.n_steps = len(df)
        self.current_step = 0
        
        self.initial_capital = 100000
        self.capital = self.initial_capital
        self.position = 0  # -1: short, 0: neutral, 1: long
        self.position_size = 0
        self.entry_price = 0
        
        self.portfolio_values = [self.initial_capital]
        self.trades = []
        
        # Actions: 0=Hold, 1=Buy, 2=Sell
        self.action_space = spaces.Discrete(3)
        
        # Observation: features from dataframe
        self.feature_columns = [col for col in df.columns if col != 'datetime']
        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf,
            shape=(len(self.feature_columns),),
            dtype=np.float32
        )
        
    def reset(self):
        """Reset environment"""
        self.current_step = 0
        self.capital = self.initial_capital
        self.position = 0
        self.position_size = 0
        self.entry_price = 0
        self.portfolio_values = [self.initial_capital]
        self.trades = []
        
        return self._get_observation()
    
    def _get_observation(self):
        """Get current state"""
        obs = self.df.loc[self.current_step, self.feature_columns].values
        return obs.astype(np.float32)
    
    def step(self, action):
        """Execute action"""
        current_price = self.df.loc[self.current_step, 'gold_Close']
        
        reward = 0
        done = False
        
        # Execute action
        if action == 1:  # Buy/Long
            if self.position <= 0:
                if self.position < 0:  # Close short
                    profit = (self.entry_price - current_price) * self.position_size
                    self.capital += profit
                    
                # Open long
                self.position_size = (self.capital * 0.95) / current_price
                self.position = 1
                self.entry_price = current_price
                
        elif action == 2:  # Sell/Short
            if self.position >= 0:
                if self.position > 0:  # Close long
                    profit = (current_price - self.entry_price) * self.position_size
                    self.capital += profit
                    
                # Open short
                self.position_size = (self.capital * 0.95) / current_price
                self.position = -1
                self.entry_price = current_price
        
        # Calculate portfolio value
        unrealized_pnl = 0
        if self.position != 0:
            if self.position > 0:
                unrealized_pnl = (current_price - self.entry_price) * self.position_size
            else:
                unrealized_pnl = (self.entry_price - current_price) * self.position_size
        
        current_value = self.capital + unrealized_pnl
        self.portfolio_values.append(current_value)
        
        # Calculate reward
        if len(self.portfolio_values) > 1:
            reward = (current_value - self.portfolio_values[-2]) / self.portfolio_values[-2]
        
        # Move to next step
        self.current_step += 1
        
        if self.current_step >= self.n_steps - 1:
            done = True
        
        next_obs = self._get_observation() if not done else self._get_observation()
        
        info = {
            'portfolio_value': current_value,
            'position': self.position
        }
        
        return next_obs, reward, done, info
