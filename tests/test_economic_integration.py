"""Test the economic integration module."""

import sys
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent.parent))

from src.analysis.economic_integration import EconomicBorderIntegrator

def test_integration():
    """Test the economic-border integration functionality."""
    print("🧪 Testing Economic-Border Integration")
    
    integrator = EconomicBorderIntegrator()
    
    # Test economic data loading
    economic_data = integrator.load_economic_data()
    print(f"✅ Economic data loaded: {len(economic_data)} records")
    assert len(economic_data) > 0, "Economic data should not be empty"
    assert 'country' in economic_data.columns, "Economic data should have country column"
    assert 'indicator' in economic_data.columns, "Economic data should have indicator column"
    assert 'value' in economic_data.columns, "Economic data should have value column"
    
    # Test border data loading
    border_data = integrator.load_border_data()
    print(f"✅ Border data loaded: {len(border_data)} pairs")
    assert len(border_data) > 0, "Border data should not be empty"
    assert 'country_1' in border_data.columns, "Border data should have country_1 column"
    assert 'country_2' in border_data.columns, "Border data should have country_2 column"
    assert 'border_length_km' in border_data.columns, "Border data should have border_length_km column"
    
    # Test country mapping functionality
    test_countries = ['China', 'India', 'United States', 'Canada']
    for country in test_countries:
        mapped = integrator.map_country_name(country)
        assert mapped is not None, f"Should be able to map country: {country}"
    
    # Test integration
    integrated = integrator.integrate_economic_border_data()
    print(f"✅ Integration successful: {len(integrated)} integrated pairs")
    assert len(integrated) > 0, "Integration should produce some results"
    
    # Test integrated data structure
    expected_cols = ['border_pair', 'country_1', 'country_2', 'border_length_km']
    for col in expected_cols:
        assert col in integrated.columns, f"Missing expected column: {col}"
    
    # Test that we have economic ratio columns
    ratio_cols = [col for col in integrated.columns if 'ratio' in col]
    assert len(ratio_cols) > 0, "Should have at least one economic ratio column"
    
    # Test economic calculations
    for idx, row in integrated.iterrows():
        assert row['border_length_km'] > 0, "Border length should be positive"
        assert ' ↔ ' in row['border_pair'], "Border pair should contain separator"
    
    # Display sample results
    if len(integrated) > 0:
        print("\n📊 Sample integrated data:")
        print(integrated[['border_pair', 'border_length_km']].head())
        
        # Show economic ratios
        if ratio_cols:
            print(f"\n💰 Economic ratios (first 3):")
            display_cols = ['border_pair'] + ratio_cols[:3]
            print(integrated[display_cols].head())
    
    print(f"✅ All tests passed! {len(integrated)} border pairs successfully integrated")

def test_economic_patterns():
    """Test the economic pattern analysis functionality."""
    print("\n🔍 Testing Economic Pattern Analysis")
    
    integrator = EconomicBorderIntegrator()
    
    # Run analysis
    results = integrator.analyze_economic_patterns()
    
    # Test results structure
    assert isinstance(results, dict), "Results should be a dictionary"
    assert 'total_border_pairs' in results, "Results should include total border pairs"
    assert 'average_border_length' in results, "Results should include average border length"
    assert 'economic_correlations' in results, "Results should include economic correlations"
    assert 'key_insights' in results, "Results should include key insights"
    
    # Test data types
    assert isinstance(results['total_border_pairs'], int), "Total border pairs should be integer"
    assert isinstance(results['economic_correlations'], dict), "Correlations should be dictionary"
    assert isinstance(results['key_insights'], list), "Insights should be list"
    
    print(f"✅ Pattern analysis passed! Found {len(results['economic_correlations'])} correlations")

if __name__ == "__main__":
    test_integration()
    test_economic_patterns()