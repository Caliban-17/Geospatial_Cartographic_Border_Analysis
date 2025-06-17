#!/usr/bin/env python3
"""Debug script to see what countries are available in economic data."""

import sys
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent.parent))

from src.analysis.economic_integration import EconomicBorderIntegrator

def main():
    print("🔍 Debugging available countries in economic data...")
    
    integrator = EconomicBorderIntegrator()
    
    # Load economic data
    economic_data = integrator.load_economic_data()
    print(f"✅ Loaded {len(economic_data)} economic records")
    
    # Get unique countries
    countries = sorted(economic_data['country'].unique())
    print(f"\n📊 Total countries available: {len(countries)}")
    
    # Show all countries
    print("\n🌍 All available countries:")
    for i, country in enumerate(countries, 1):
        print(f"{i:3d}. {country}")
    
    # Check specific countries we need
    missing_countries = ['Argentina', 'Chile', 'Indonesia', 'Malaysia', 'Bolivia', 'Peru']
    print(f"\n❓ Checking for missing countries:")
    
    for country in missing_countries:
        if country in countries:
            print(f"✅ {country} - FOUND")
        else:
            print(f"❌ {country} - NOT FOUND")
            # Look for similar names
            similar = [c for c in countries if country.lower() in c.lower() or c.lower() in country.lower()]
            if similar:
                print(f"   🔍 Similar names: {similar}")

if __name__ == "__main__":
    main()