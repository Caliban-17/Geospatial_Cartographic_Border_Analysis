#!/usr/bin/env python3
"""
FIXED: Real data download script with WORKING geographic sources
"""
import argparse
import os
import sys
import requests
import yaml
import zipfile
import pandas as pd
from pathlib import Path
import logging
import time
import json

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BorderDataDownloader:
    def __init__(self, config_path, output_dir):
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def download_with_retry(self, url, output_path, max_retries=3):
        """Download file with retry logic."""
        for attempt in range(max_retries):
            try:
                logger.info(f"Downloading {os.path.basename(output_path)} (attempt {attempt + 1})")
                
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
                }
                
                response = requests.get(url, stream=True, timeout=30, headers=headers)
                response.raise_for_status()
                
                total_size = int(response.headers.get('content-length', 0))
                downloaded = 0
                
                with open(output_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            if total_size > 0:
                                progress = (downloaded / total_size) * 100
                                print(f"\rProgress: {progress:.1f}%", end='', flush=True)
                
                print(f"\n✅ Downloaded: {output_path}")
                return True
                
            except Exception as e:
                logger.warning(f"Attempt {attempt + 1} failed: {e}")
                if attempt == max_retries - 1:
                    logger.error(f"Failed to download {url}")
                    return False
                time.sleep(2 ** attempt)
        
        return False
    
    def download_world_boundaries_github(self):
        """Download world country boundaries from reliable GitHub sources."""
        logger.info("🗺️  Downloading world country boundaries from GitHub...")
        
        geo_dir = self.output_dir / 'geographic'
        geo_dir.mkdir(exist_ok=True)
        
        # Multiple reliable sources to try
        sources = [
            {
                'name': 'datasets/geo-countries',
                'url': 'https://raw.githubusercontent.com/datasets/geo-countries/main/data/countries.geojson',
                'filename': 'world_countries_datasets.geojson'
            },
            {
                'name': 'johan/world.geo.json',  
                'url': 'https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json',
                'filename': 'world_countries_johan.geojson'
            },
            {
                'name': 'martynafford/natural-earth-geojson',
                'url': 'https://raw.githubusercontent.com/martynafford/natural-earth-geojson/master/10m/cultural/ne_10m_admin_0_countries.geojson',
                'filename': 'world_countries_natural_earth.geojson'
            }
        ]
        
        success_count = 0
        
        for source in sources:
            try:
                logger.info(f"Trying {source['name']}...")
                response = requests.get(source['url'], timeout=30)
                response.raise_for_status()
                
                data = response.json()
                
                # Validate it's proper GeoJSON
                if 'features' in data and len(data['features']) > 100:
                    output_path = geo_dir / source['filename']
                    with open(output_path, 'w') as f:
                        json.dump(data, f, indent=2)
                    
                    logger.info(f"✅ Downloaded {source['name']}: {len(data['features'])} countries")
                    success_count += 1
                    
                    # Create a standardized version for the pipeline
                    if success_count == 1:  # Use first successful download as primary
                        primary_path = geo_dir / 'world_countries_primary.geojson'
                        with open(primary_path, 'w') as f:
                            json.dump(data, f, indent=2)
                        logger.info(f"✅ Created primary boundaries file: {primary_path}")
                else:
                    logger.warning(f"Invalid GeoJSON from {source['name']}")
                    
            except Exception as e:
                logger.warning(f"Failed to download from {source['name']}: {e}")
        
        return success_count > 0
    
    def download_historical_boundaries(self):
        """Download historical boundary data for border change analysis."""
        logger.info("📜 Downloading historical boundary data...")
        
        geo_dir = self.output_dir / 'geographic'
        geo_dir.mkdir(exist_ok=True)
        
        # Try historical basemaps repository
        historical_url = "https://raw.githubusercontent.com/aourednik/historical-basemaps/master/GeoJSON/World_1938.geojson"
        
        try:
            response = requests.get(historical_url, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            if 'features' in data:
                historical_path = geo_dir / 'world_1938_historical.geojson'
                with open(historical_path, 'w') as f:
                    json.dump(data, f, indent=2)
                
                logger.info(f"✅ Downloaded historical boundaries (1938): {len(data['features'])} features")
                return True
            else:
                logger.warning("Invalid historical boundary data")
                return False
                
        except Exception as e:
            logger.warning(f"Failed to download historical boundaries: {e}")
            return False
    
    def download_world_bank_enhanced(self):
        """Download enhanced World Bank economic data."""
        logger.info("💰 Downloading World Bank economic indicators...")
        
        econ_dir = self.output_dir / 'economic'
        econ_dir.mkdir(exist_ok=True)
        
        countries = ['USA', 'CAN', 'DEU', 'POL', 'FRA', 'ESP', 'CHN', 'RUS', 'IND', 'PAK']
        indicators = self.config['economic']['world_bank']['indicators']
        
        base_url = self.config['economic']['world_bank']['base_url']
        success_count = 0
        
        for indicator_name, indicator_code in indicators.items():
            try:
                country_codes = ';'.join(countries)
                url = f"{base_url}country/{country_codes}/indicator/{indicator_code}?format=json&per_page=5000&date=1990:2020"
                
                logger.info(f"Fetching {indicator_name} data...")
                response = requests.get(url, timeout=30)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    json_path = econ_dir / f'{indicator_name}_raw.json'
                    with open(json_path, 'w') as f:
                        json.dump(data, f, indent=2)
                    
                    logger.info(f"✅ Saved: {json_path}")
                    success_count += 1
                else:
                    logger.warning(f"Failed to fetch {indicator_name}: {response.status_code}")
                    
            except Exception as e:
                logger.error(f"Error downloading {indicator_name}: {e}")
        
        return success_count > 0
    
    def create_enhanced_sample_data(self):
        """Create enhanced sample border change dataset."""
        logger.info("📊 Creating enhanced sample datasets...")
        
        sample_data = {
            'country_pair': [
                'USA-CAN', 'DEU-POL', 'FRA-ESP', 'CHN-RUS', 'IND-PAK',
                'KOR-PRK', 'ISR-PSE', 'GRC-TUR', 'IRN-IRQ', 'ARG-CHL'
            ],
            'year': [1950, 1945, 1960, 1970, 1947, 1953, 1967, 1923, 1980, 1902],
            'territory_change_km2': [0, 45000, 0, 1200, 0, 0, 5800, 15000, 2400, 450],
            'border_length_km': [8891, 467, 623, 4209, 3323, 238, 1006, 192, 1458, 5308],
            'border_type': [
                'stable', 'post_war', 'stable', 'negotiated', 'partition',
                'armistice', 'occupation', 'population_exchange', 'war', 'arbitration'
            ],
            'gdp_ratio': [1.2, 0.3, 0.9, 0.1, 0.8, 15.0, 8.5, 0.6, 0.3, 1.1],
            'democracy_gap': [0.1, 0.8, 0.2, 0.9, 0.3, 1.0, 0.7, 0.4, 0.8, 0.2],
            'military_ratio': [1.5, 0.2, 1.1, 0.15, 1.2, 20.0, 5.0, 0.8, 0.4, 1.3],
            'conflict_history': [0, 2, 0, 1, 3, 1, 4, 2, 3, 1],
            'trade_dependency': [0.85, 0.12, 0.45, 0.08, 0.05, 0.01, 0.02, 0.15, 0.18, 0.25]
        }
        
        df = pd.DataFrame(sample_data)
        sample_path = self.output_dir / 'enhanced_border_analysis.csv'
        df.to_csv(sample_path, index=False)
        logger.info(f"✅ Created enhanced sample data: {sample_path}")
        
        # Create metadata
        metadata = {
            'description': 'Enhanced border change analysis dataset',
            'source': 'Curated sample for testing border analysis pipeline',
            'features': list(sample_data.keys()),
            'records': len(df),
            'country_pairs': len(set(sample_data['country_pair'])),
            'time_span': f"{min(sample_data['year'])}-{max(sample_data['year'])}",
            'note': 'Contains both stable borders (USA-CAN) and volatile borders (IND-PAK)'
        }
        
        metadata_path = self.output_dir / 'dataset_metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Download border analysis data')
    parser.add_argument('--config', required=True, help='Config file path')
    parser.add_argument('--output', required=True, help='Output directory')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    logger.info(f"🚀 Starting ENHANCED data download to {args.output}")
    
    try:
        downloader = BorderDataDownloader(args.config, args.output)
        
        downloads = []
        downloads.append(("World Boundaries (GitHub)", downloader.download_world_boundaries_github()))
        downloads.append(("Historical Boundaries", downloader.download_historical_boundaries()))
        downloads.append(("World Bank Enhanced", downloader.download_world_bank_enhanced()))
        downloads.append(("Enhanced Sample Data", downloader.create_enhanced_sample_data()))
        
        successful = sum(1 for _, success in downloads if success)
        total = len(downloads)
        
        logger.info(f"\n📊 Download Summary: {successful}/{total} successful")
        
        for name, success in downloads:
            status = "✅" if success else "❌"
            logger.info(f"  {status} {name}")
        
        flag_file = Path(args.output) / 'download_complete.flag'
        with open(flag_file, 'w') as f:
            f.write(f"ENHANCED Download completed: {successful}/{total} successful\n")
            f.write(f"Datasets: {', '.join(name for name, success in downloads if success)}\n")
            f.write(f"Geographic: Multiple GitHub sources with {successful-2 if successful >= 2 else 0} working\n")
        
        return 0 if successful > 0 else 1
        
    except Exception as e:
        logger.error(f"Download failed: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
