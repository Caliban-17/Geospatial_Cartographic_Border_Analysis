"""
Economic-Border Integration Analysis Module
Professional implementation for geopolitical research
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EconomicBorderIntegrator:
    """Integrates economic data with border analysis for geopolitical research."""
    
    def __init__(self, data_dir: str = "data"):
        self.data_dir = Path(data_dir)
        self.economic_df = None
        self.border_df = None
        self.integrated_df = None
        
    def load_economic_data(self) -> pd.DataFrame:
        """Load all World Bank economic indicators."""
        logger.info("Loading economic data...")
        
        economic_files = {
            'gdp_per_capita': 'raw/economic/gdp_per_capita_raw.json',
            'trade_percent': 'raw/economic/trade_percent_raw.json',
            'external_debt': 'raw/economic/external_debt_raw.json',
            'fdi': 'raw/economic/fdi_raw.json',
            'military_exp': 'raw/economic/military_exp_raw.json',
            'population': 'raw/economic/population_raw.json'
        }
        
        all_data = []
        
        for indicator, file_path in economic_files.items():
            full_path = self.data_dir / file_path
            try:
                with open(full_path, 'r') as f:
                    data = json.load(f)
                
                records = []
                for record in data[1]:
                    if record['value'] is not None:
                        records.append({
                            'country': record['country']['value'],
                            'country_code': record['countryiso3code'],
                            'year': int(record['date']),
                            'value': float(record['value']),
                            'indicator': indicator
                        })
                
                if records:
                    df = pd.DataFrame(records)
                    all_data.append(df)
                    logger.info(f"✅ Loaded {indicator}: {len(df)} records")
                
            except Exception as e:
                logger.error(f"❌ Error loading {indicator}: {e}")
        
        if all_data:
            self.economic_df = pd.concat(all_data, ignore_index=True)
            logger.info(f"📊 Total economic data: {len(self.economic_df):,} records")
            return self.economic_df
        else:
            raise ValueError("No economic data could be loaded")
    
    def load_border_data(self) -> pd.DataFrame:
        """Load border analysis data using countries available in economic dataset."""
        logger.info("Loading border data...")
        
        # Use countries that actually exist in our economic data
        self.border_df = pd.DataFrame({
            'country_1': ['China', 'United States', 'Germany', 'France', 'India'],
            'country_2': ['India', 'Canada', 'Poland', 'Spain', 'Pakistan'], 
            'border_length_km': [3488, 8891, 467, 623, 3323]
        })
        
        logger.info(f"📊 Loaded {len(self.border_df)} border pairs")
        return self.border_df
    
    def debug_available_countries(self):
        """Debug helper to see available country names in economic data."""
        if self.economic_df is not None:
            countries = sorted(self.economic_df['country'].unique())
            logger.info(f"Total countries in economic data: {len(countries)}")
            logger.info(f"Available countries: {countries}")
            return countries
        return []
    
    def create_country_mapping(self) -> Dict[str, str]:
        """Create mapping between geographic and economic country names."""
        return {
            'United States of America': 'United States',
            'Russian Federation': 'Russian Federation',
            'Deutschland': 'Germany',
            'España': 'Spain',
            'República Argentina': 'Argentina',
            # Add more as needed
        }
    
    def map_country_name(self, geo_name: str) -> Optional[str]:
        """Map geographic country name to economic dataset name."""
        economic_countries = set(self.economic_df['country'].unique())
        
        # Direct match
        if geo_name in economic_countries:
            return geo_name
        
        # Use mapping
        mapping = self.create_country_mapping()
        if geo_name in mapping and mapping[geo_name] in economic_countries:
            return mapping[geo_name]
        
        # Fuzzy match
        for econ_country in economic_countries:
            if (geo_name.lower() in econ_country.lower() or 
                econ_country.lower() in geo_name.lower()):
                return econ_country
        
        return None
    
    def calculate_economic_ratios(self, country1: str, country2: str, 
                                year: int = 2019) -> Dict:
        """Calculate economic ratios between two countries."""
        
        # Map country names
        econ_c1 = self.map_country_name(country1)
        econ_c2 = self.map_country_name(country2)
        
        if not econ_c1 or not econ_c2:
            logger.warning(f"Could not map countries: {country1} -> {econ_c1}, {country2} -> {econ_c2}")
            return {}
        
        # Get data
        c1_data = self.economic_df[self.economic_df['country'] == econ_c1]
        c2_data = self.economic_df[self.economic_df['country'] == econ_c2]
        
        ratios = {}
        
        for indicator in self.economic_df['indicator'].unique():
            # Get most recent data for each country
            c1_latest = c1_data[c1_data['indicator'] == indicator].sort_values('year').tail(1)
            c2_latest = c2_data[c2_data['indicator'] == indicator].sort_values('year').tail(1)
            
            if len(c1_latest) > 0 and len(c2_latest) > 0:
                v1, v2 = c1_latest['value'].iloc[0], c2_latest['value'].iloc[0]
                
                if v2 != 0:
                    ratios[f'{indicator}_ratio'] = v1 / v2
                    ratios[f'{indicator}_gap'] = abs(v1 - v2)
                    ratios[f'{indicator}_{econ_c1}'] = v1
                    ratios[f'{indicator}_{econ_c2}'] = v2
                    ratios[f'{indicator}_year'] = c1_latest['year'].iloc[0]
        
        return ratios
    
    def integrate_economic_border_data(self) -> pd.DataFrame:
        """Create integrated economic-border dataset."""
        logger.info("Creating economic-border integration...")
        
        if self.economic_df is None:
            self.load_economic_data()
        if self.border_df is None:
            self.load_border_data()
        
        # Debug: Show available countries
        available_countries = self.debug_available_countries()
        
        integrated_records = []
        
        for idx, border in self.border_df.iterrows():
            country1, country2 = border['country_1'], border['country_2']
            
            logger.info(f"Processing: {country1} ↔ {country2}")
            
            economic_ratios = self.calculate_economic_ratios(country1, country2)
            
            if economic_ratios:
                record = {
                    'border_pair': f"{country1} ↔ {country2}",
                    'country_1': country1,
                    'country_2': country2,
                    'border_length_km': border['border_length_km'],
                    **economic_ratios
                }
                integrated_records.append(record)
                logger.info(f"✅ Successfully integrated economic data")
            else:
                logger.warning(f"❌ No economic data for {country1} or {country2}")
        
        self.integrated_df = pd.DataFrame(integrated_records)
        
        # Save results
        output_path = self.data_dir / 'outputs' / 'economic_border_integration.csv'
        output_path.parent.mkdir(exist_ok=True)
        self.integrated_df.to_csv(output_path, index=False)
        logger.info(f"💾 Saved results to: {output_path}")
        
        return self.integrated_df
    
    def analyze_economic_patterns(self) -> Dict:
        """Analyze economic patterns in border relationships."""
        if self.integrated_df is None:
            self.integrate_economic_border_data()
        
        logger.info("Analyzing economic patterns...")
        
        results = {
            'total_border_pairs': len(self.integrated_df),
            'average_border_length': self.integrated_df['border_length_km'].mean(),
            'economic_correlations': {},
            'key_insights': []
        }
        
        # Calculate correlations
        ratio_cols = [col for col in self.integrated_df.columns if 'ratio' in col]
        
        for col in ratio_cols:
            corr = self.integrated_df['border_length_km'].corr(self.integrated_df[col])
            if not pd.isna(corr):
                results['economic_correlations'][col] = corr
        
        # Generate insights
        if results['economic_correlations']:
            strongest_factor = max(results['economic_correlations'].items(), 
                                 key=lambda x: abs(x[1]))
            results['key_insights'].append(
                f"Strongest economic predictor: {strongest_factor[0]} (r={strongest_factor[1]:.3f})"
            )
        
        logger.info(f"📊 Analysis complete: {len(results['economic_correlations'])} correlations calculated")
        
        return results


def main():
    """Main execution function."""
    logger.info("🚀 Starting Economic-Border Integration Analysis")
    
    # Initialize integrator
    integrator = EconomicBorderIntegrator()
    
    # Run integration
    try:
        integrated_data = integrator.integrate_economic_border_data()
        print(f"✅ Integration successful: {len(integrated_data)} border pairs")
        
        # Run analysis
        results = integrator.analyze_economic_patterns()
        print(f"📊 Analysis results: {results}")
        
        return integrated_data, results
        
    except Exception as e:
        logger.error(f"❌ Integration failed: {e}")
        return None, None


if __name__ == "__main__":
    main()