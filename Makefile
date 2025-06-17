# Border Change Analysis Project Makefile
# Optimized for: /Users/dominicgarvey/Code_Projects/Border_Change_Analysis
# Run from project root directory

# Variables
PROJECT_NAME := border-change-analysis
PROJECT_ROOT := $(shell pwd)
PYTHON := python3
VENV := venv
VENV_BIN := $(VENV)/bin
PIP := $(VENV_BIN)/pip
PYTHON_VENV := $(VENV_BIN)/python
ACTIVATE := $(VENV_BIN)/activate

# Directory structure
DATA_DIR := data
RAW_DATA := $(DATA_DIR)/raw
PROCESSED_DATA := $(DATA_DIR)/processed
OUTPUTS := $(DATA_DIR)/outputs
SRC := src
SCRIPTS := scripts
TESTS := tests
NOTEBOOKS := notebooks
CONFIG := config

# Color codes for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help setup install-deps create-dirs download-data preprocess features model analyze test clean report all status

##@ Setup Commands
help: ## Display this help message
	@echo ""
	@echo "$(BLUE)Border Change Analysis - Project Makefile$(NC)"
	@echo "$(YELLOW)Current directory: $(PROJECT_ROOT)$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

check-directory: ## Verify we're in the correct directory
	@echo "$(BLUE)📍 Checking current directory...$(NC)"
	@if [ "$(shell basename $(PROJECT_ROOT))" != "Border_Change_Analysis" ]; then \
		echo "$(RED)❌ Warning: Expected to be in Border_Change_Analysis directory$(NC)"; \
		echo "$(YELLOW)Current: $(PROJECT_ROOT)$(NC)"; \
		echo "$(YELLOW)Expected: .../Border_Change_Analysis$(NC)"; \
	else \
		echo "$(GREEN)✅ Correct directory: $(PROJECT_ROOT)$(NC)"; \
	fi

check-python: ## Check Python installation
	@echo "$(BLUE)🐍 Checking Python installation...$(NC)"
	@if command -v $(PYTHON) >/dev/null 2>&1; then \
		echo "$(GREEN)✅ Python found: $(shell $(PYTHON) --version)$(NC)"; \
	else \
		echo "$(RED)❌ Python3 not found. Please install Python 3.8+$(NC)"; \
		exit 1; \
	fi

setup: check-directory check-python create-dirs setup-venv install-deps init-config init-files ## Complete project setup
	@echo "$(GREEN)🎉 Project setup complete!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Run: $(GREEN)make download-data$(NC)"
	@echo "  2. Run: $(GREEN)make all$(NC) for full pipeline"
	@echo "  3. Check status: $(GREEN)make status$(NC)"

create-dirs: ## Create project directory structure
	@echo "$(BLUE)📁 Creating directory structure...$(NC)"
	@mkdir -p $(RAW_DATA) $(PROCESSED_DATA) $(OUTPUTS)
	@mkdir -p $(SRC)/data $(SRC)/models $(SRC)/analysis $(SRC)/utils
	@mkdir -p $(SCRIPTS) $(TESTS) $(NOTEBOOKS) $(CONFIG)
	@mkdir -p logs
	@touch $(SRC)/__init__.py $(SRC)/data/__init__.py $(SRC)/models/__init__.py
	@touch $(SRC)/analysis/__init__.py $(SRC)/utils/__init__.py $(TESTS)/__init__.py
	@touch $(RAW_DATA)/.gitkeep $(PROCESSED_DATA)/.gitkeep $(OUTPUTS)/.gitkeep
	@echo "$(GREEN)✅ Directory structure created$(NC)"

setup-venv: ## Create virtual environment
	@echo "$(BLUE)🐍 Setting up virtual environment...$(NC)"
	@if [ ! -d "$(VENV)" ]; then \
		$(PYTHON) -m venv $(VENV); \
		echo "$(GREEN)✅ Virtual environment created at $(PROJECT_ROOT)/$(VENV)$(NC)"; \
	else \
		echo "$(GREEN)✅ Virtual environment already exists$(NC)"; \
	fi

$(ACTIVATE): setup-venv
	@test -f $(ACTIVATE)

install-deps: $(ACTIVATE) requirements.txt ## Install Python dependencies
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@$(PIP) install --upgrade pip setuptools wheel
	@$(PIP) install -r requirements.txt
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

init-config: ## Initialize configuration files
	@echo "$(BLUE)⚙️  Creating configuration files...$(NC)"
	@mkdir -p $(CONFIG)
	@echo "geographic:" > $(CONFIG)/data_sources.yaml
	@echo "  natural_earth:" >> $(CONFIG)/data_sources.yaml
	@echo "    url: 'https://www.naturalearthdata.com/downloads/'" >> $(CONFIG)/data_sources.yaml
	@echo "economic:" >> $(CONFIG)/data_sources.yaml
	@echo "  world_bank:" >> $(CONFIG)/data_sources.yaml
	@echo "    base_url: 'https://api.worldbank.org/v2/'" >> $(CONFIG)/data_sources.yaml
	@echo "temporal:" >> $(CONFIG)/data_sources.yaml
	@echo "  start_year: 1945" >> $(CONFIG)/data_sources.yaml
	@echo "  end_year: 2023" >> $(CONFIG)/data_sources.yaml
	@echo "target_variables:" > $(CONFIG)/model_config.yaml
	@echo "  - territory_change_km2" >> $(CONFIG)/model_config.yaml
	@echo "  - border_volatility_index" >> $(CONFIG)/model_config.yaml
	@echo "geographic:" > $(CONFIG)/feature_config.yaml
	@echo "  - border_length" >> $(CONFIG)/feature_config.yaml
	@echo "  - river_barrier_pct" >> $(CONFIG)/feature_config.yaml
	@echo "$(GREEN)✅ Configuration files created$(NC)"

init-files: ## Create initial Python files
	@echo "$(BLUE)📝 Creating initial files...$(NC)"
	@echo "# Border Change Analysis" > README.md
	@echo "This project analyzes geopolitical factors affecting border changes." >> README.md
	@echo "" >> README.md
	@echo "## Quick Start" >> README.md
	@echo "\`\`\`bash" >> README.md
	@echo "make setup    # Initial setup" >> README.md
	@echo "make all      # Run full pipeline" >> README.md
	@echo "make status   # Check progress" >> README.md
	@echo "\`\`\`" >> README.md
	@echo "$(GREEN)✅ Initial files created$(NC)"

##@ Data Pipeline
download-data: $(RAW_DATA)/download_complete.flag ## Download all raw datasets

$(RAW_DATA)/download_complete.flag: $(SCRIPTS)/download_data.py $(ACTIVATE)
	@echo "$(BLUE)🌐 Downloading raw data...$(NC)"
	@$(PYTHON_VENV) $(SCRIPTS)/download_data.py --config $(CONFIG)/data_sources.yaml --output $(RAW_DATA) --verbose
	@touch $@
	@echo "$(GREEN)✅ Data download complete$(NC)"

preprocess: $(PROCESSED_DATA)/preprocessing_complete.flag ## Clean and preprocess raw data

$(PROCESSED_DATA)/preprocessing_complete.flag: $(RAW_DATA)/download_complete.flag $(SRC)/data/preprocessors.py
	@echo "$(BLUE)🔧 Preprocessing data...$(NC)"
	@echo "import sys; sys.path.insert(0, '$(PROJECT_ROOT)'); print('Preprocessing placeholder')" | $(PYTHON_VENV)
	@touch $@
	@echo "$(GREEN)✅ Data preprocessing complete$(NC)"

features: $(PROCESSED_DATA)/features_complete.flag ## Generate engineered features

$(PROCESSED_DATA)/features_complete.flag: $(PROCESSED_DATA)/preprocessing_complete.flag $(SRC)/data/feature_engineering.py
	@echo "$(BLUE)⚡ Engineering features...$(NC)"
	@echo "print('Feature engineering placeholder')" | $(PYTHON_VENV)
	@touch $@
	@echo "$(GREEN)✅ Feature engineering complete$(NC)"

##@ Modeling
model: $(OUTPUTS)/model_complete.flag ## Train and validate models

$(OUTPUTS)/model_complete.flag: $(PROCESSED_DATA)/features_complete.flag $(SRC)/models/border_model.py
	@echo "$(BLUE)🤖 Training models...$(NC)"
	@echo "print('Model training placeholder')" | $(PYTHON_VENV)
	@touch $@
	@echo "$(GREEN)✅ Model training complete$(NC)"

validate: $(OUTPUTS)/validation_complete.flag ## Cross-validate models

$(OUTPUTS)/validation_complete.flag: $(OUTPUTS)/model_complete.flag $(SRC)/models/validators.py
	@echo "$(BLUE)✅ Validating models...$(NC)"
	@echo "print('Model validation placeholder')" | $(PYTHON_VENV)
	@touch $@
	@echo "$(GREEN)✅ Model validation complete$(NC)"

##@ Analysis
analyze: $(OUTPUTS)/analysis_complete.flag ## Generate analysis and insights

$(OUTPUTS)/analysis_complete.flag: $(OUTPUTS)/validation_complete.flag $(SRC)/analysis/exploratory.py
	@echo "$(BLUE)📊 Running analysis...$(NC)"
	@echo "print('Analysis placeholder')" | $(PYTHON_VENV)
	@touch $@
	@echo "$(GREEN)✅ Analysis complete$(NC)"

##@ Testing
test: $(ACTIVATE) ## Run all tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@if [ -d "$(TESTS)" ] && [ "$$(ls -A $(TESTS) 2>/dev/null)" ]; then \
		$(PYTHON_VENV) -m pytest $(TESTS) -v --tb=short; \
	else \
		echo "$(YELLOW)⚠️  No tests found in $(TESTS)$(NC)"; \
	fi
	@echo "$(GREEN)✅ Tests completed$(NC)"

lint: $(ACTIVATE) ## Run code linting
	@echo "$(BLUE)🔍 Linting code...$(NC)"
	@if [ -d "$(SRC)" ]; then \
		$(PYTHON_VENV) -m flake8 $(SRC) --max-line-length=88 --extend-ignore=E203,W503 || true; \
	fi
	@echo "$(GREEN)✅ Linting completed$(NC)"

format: $(ACTIVATE) ## Format code with black
	@echo "$(BLUE)🎨 Formatting code...$(NC)"
	@if [ -d "$(SRC)" ]; then \
		$(PYTHON_VENV) -m black $(SRC) $(SCRIPTS) || true; \
	fi
	@echo "$(GREEN)✅ Code formatted$(NC)"

##@ Documentation
report: $(OUTPUTS)/final_report.html ## Generate final report

$(OUTPUTS)/final_report.html: $(OUTPUTS)/analysis_complete.flag $(SCRIPTS)/generate_report.py
	@echo "$(BLUE)📋 Generating final report...$(NC)"
	@$(PYTHON_VENV) $(SCRIPTS)/generate_report.py --data $(OUTPUTS) --output $@
	@echo "$(GREEN)✅ Report generated: $@$(NC)"

##@ Utilities
status: ## Show pipeline status
	@echo ""
	@echo "$(BLUE)📊 Border Change Analysis - Pipeline Status$(NC)"
	@echo "$(BLUE)==============================================$(NC)"
	@echo "$(YELLOW)📍 Project directory: $(PROJECT_ROOT)$(NC)"
	@echo ""
	@printf "📁 Project setup:     "; [ -d "$(VENV)" ] && echo "$(GREEN)✅ Complete$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "📦 Dependencies:      "; [ -f "$(ACTIVATE)" ] && echo "$(GREEN)✅ Installed$(NC)" || echo "$(RED)❌ Missing$(NC)"
	@printf "⚙️  Configuration:     "; [ -f "$(CONFIG)/data_sources.yaml" ] && echo "$(GREEN)✅ Created$(NC)" || echo "$(RED)❌ Missing$(NC)"
	@printf "🌐 Raw data:          "; [ -f "$(RAW_DATA)/download_complete.flag" ] && echo "$(GREEN)✅ Downloaded$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "🔧 Preprocessing:     "; [ -f "$(PROCESSED_DATA)/preprocessing_complete.flag" ] && echo "$(GREEN)✅ Complete$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "⚡ Features:          "; [ -f "$(PROCESSED_DATA)/features_complete.flag" ] && echo "$(GREEN)✅ Complete$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "🤖 Models:            "; [ -f "$(OUTPUTS)/model_complete.flag" ] && echo "$(GREEN)✅ Trained$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "✅ Validation:        "; [ -f "$(OUTPUTS)/validation_complete.flag" ] && echo "$(GREEN)✅ Complete$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "📊 Analysis:          "; [ -f "$(OUTPUTS)/analysis_complete.flag" ] && echo "$(GREEN)✅ Complete$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@printf "📋 Report:            "; [ -f "$(OUTPUTS)/final_report.html" ] && echo "$(GREEN)✅ Generated$(NC)" || echo "$(RED)❌ Pending$(NC)"
	@echo ""

info: ## Show project information
	@echo "$(BLUE)📋 Project Information$(NC)"
	@echo "======================="
	@echo "Name: $(PROJECT_NAME)"
	@echo "Root: $(PROJECT_ROOT)"
	@echo "Python: $(shell which $(PYTHON) 2>/dev/null || echo 'Not found')"
	@echo "Make: $(shell make --version | head -n1)"
	@echo "OS: $(shell uname -s)"
	@echo ""

clean-data: ## Remove processed data (keep raw data)
	@echo "$(BLUE)🧹 Cleaning processed data...$(NC)"
	@rm -rf $(PROCESSED_DATA)/* $(OUTPUTS)/*
	@mkdir -p $(PROCESSED_DATA) $(OUTPUTS)
	@touch $(PROCESSED_DATA)/.gitkeep $(OUTPUTS)/.gitkeep
	@echo "$(GREEN)✅ Processed data cleaned$(NC)"

clean-models: ## Remove model outputs only
	@echo "$(BLUE)🧹 Cleaning model outputs...$(NC)"
	@rm -f $(OUTPUTS)/model_*.pkl $(OUTPUTS)/validation_*.csv $(OUTPUTS)/*.flag
	@echo "$(GREEN)✅ Model outputs cleaned$(NC)"

clean-cache: ## Remove Python cache files
	@echo "$(BLUE)🧹 Cleaning Python cache...$(NC)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@find . -name "*.pyo" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Cache cleaned$(NC)"

clean-all: clean-cache ## Remove all generated files (except raw data)
	@echo "$(BLUE)🧹 Cleaning all generated files...$(NC)"
	@rm -rf $(PROCESSED_DATA)/* $(OUTPUTS)/* logs/*
	@mkdir -p $(PROCESSED_DATA) $(OUTPUTS) logs
	@touch $(PROCESSED_DATA)/.gitkeep $(OUTPUTS)/.gitkeep logs/.gitkeep
	@echo "$(GREEN)✅ All generated files cleaned$(NC)"

reset: clean-all ## Full reset (remove venv and all data)
	@echo "$(BLUE)🔄 Full project reset...$(NC)"
	@rm -rf $(VENV)
	@rm -rf $(RAW_DATA)/*
	@rm -rf $(CONFIG)/*.yaml
	@touch $(RAW_DATA)/.gitkeep
	@echo "$(GREEN)✅ Project reset complete$(NC)"

##@ Meta Commands
all: setup download-data preprocess features model validate analyze ## Run complete pipeline
	@echo "$(GREEN)🎉 Complete pipeline executed successfully!$(NC)"
	@echo "$(YELLOW)📋 Check results in: $(OUTPUTS)/$(NC)"

quick-start: setup ## Setup project for development
	@echo "$(GREEN)⚡ Quick start complete!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. $(GREEN)make download-data$(NC) - Download datasets"
	@echo "  2. $(GREEN)make features$(NC) - Generate features"
	@echo "  3. $(GREEN)make model$(NC) - Train models"

dev-setup: setup lint format ## Setup for development with code quality tools
	@echo "$(GREEN)🔧 Development setup complete!$(NC)"

# File creation rules
requirements.txt:
	@echo "$(BLUE)📝 Creating requirements.txt...$(NC)"
	@echo "# Core data science" > requirements.txt
	@echo "pandas>=1.5.0" >> requirements.txt
	@echo "numpy>=1.21.0" >> requirements.txt
	@echo "scikit-learn>=1.2.0" >> requirements.txt
	@echo "" >> requirements.txt
	@echo "# Geospatial" >> requirements.txt
	@echo "geopandas>=0.12.0" >> requirements.txt
	@echo "shapely>=2.0.0" >> requirements.txt
	@echo "rasterio>=1.3.0" >> requirements.txt
	@echo "folium>=0.14.0" >> requirements.txt
	@echo "pyproj>=3.4.0" >> requirements.txt
	@echo "" >> requirements.txt
	@echo "# Data collection" >> requirements.txt
	@echo "requests>=2.28.0" >> requirements.txt
	@echo "beautifulsoup4>=4.11.0" >> requirements.txt
	@echo "openpyxl>=3.0.0" >> requirements.txt
	@echo "" >> requirements.txt
	@echo "# Configuration" >> requirements.txt
	@echo "pyyaml>=6.0" >> requirements.txt
	@echo "python-dotenv>=0.19.0" >> requirements.txt
	@echo "" >> requirements.txt
	@echo "# Visualization" >> requirements.txt
	@echo "matplotlib>=3.6.0" >> requirements.txt
	@echo "seaborn>=0.11.0" >> requirements.txt
	@echo "plotly>=5.11.0" >> requirements.txt
	@echo "" >> requirements.txt
	@echo "# Development tools" >> requirements.txt
	@echo "pytest>=7.0.0" >> requirements.txt
	@echo "flake8>=5.0.0" >> requirements.txt
	@echo "black>=22.0.0" >> requirements.txt
	@echo "jupyter>=1.0.0" >> requirements.txt
	@echo "ipykernel>=6.15.0" >> requirements.txt
	@echo "$(GREEN)✅ requirements.txt created$(NC)"

$(SCRIPTS)/download_data.py:
	@echo "$(BLUE)📝 Creating download script...$(NC)"
	@mkdir -p $(SCRIPTS)
	@echo "#!/usr/bin/env python3" > $@
	@echo "import argparse" >> $@
	@echo "import os" >> $@
	@echo "import yaml" >> $@
	@echo "from pathlib import Path" >> $@
	@echo "" >> $@
	@echo "def main():" >> $@
	@echo "    parser = argparse.ArgumentParser()" >> $@
	@echo "    parser.add_argument('--config', required=True)" >> $@
	@echo "    parser.add_argument('--output', required=True)" >> $@
	@echo "    parser.add_argument('--verbose', action='store_true')" >> $@
	@echo "    args = parser.parse_args()" >> $@
	@echo "" >> $@
	@echo "    output_dir = Path(args.output)" >> $@
	@echo "    output_dir.mkdir(parents=True, exist_ok=True)" >> $@
	@echo "    print(f'Download placeholder to {output_dir}')" >> $@
	@echo "" >> $@
	@echo "if __name__ == '__main__':" >> $@
	@echo "    main()" >> $@
	@chmod +x $@
	@echo "$(GREEN)✅ Download script created$(NC)"

$(SCRIPTS)/generate_report.py:
	@echo "$(BLUE)📝 Creating report script...$(NC)"
	@mkdir -p $(SCRIPTS)
	@echo "#!/usr/bin/env python3" > $@
	@echo "import argparse" >> $@
	@echo "" >> $@
	@echo "def main():" >> $@
	@echo "    parser = argparse.ArgumentParser()" >> $@
	@echo "    parser.add_argument('--data', required=True)" >> $@
	@echo "    parser.add_argument('--output', required=True)" >> $@
	@echo "    args = parser.parse_args()" >> $@
	@echo "" >> $@
	@echo "    html_content = '''<!DOCTYPE html>" >> $@
	@echo "<html><head><title>Border Analysis Report</title></head>" >> $@
	@echo "<body><h1>Border Change Analysis Report</h1>" >> $@
	@echo "<p>Report generated successfully.</p></body></html>'''" >> $@
	@echo "" >> $@
	@echo "    with open(args.output, 'w') as f:" >> $@
	@echo "        f.write(html_content)" >> $@
	@echo "    print(f'Report generated: {args.output}')" >> $@
	@echo "" >> $@
	@echo "if __name__ == '__main__':" >> $@
	@echo "    main()" >> $@
	@chmod +x $@
	@echo "$(GREEN)✅ Report script created$(NC)"

# Python file templates
$(SRC)/data/preprocessors.py:
	@mkdir -p $(SRC)/data
	@echo "# Data preprocessing module" > $@
	@echo "class DataPreprocessor:" >> $@
	@echo "    def __init__(self, raw_dir, processed_dir):" >> $@
	@echo "        self.raw_dir = raw_dir" >> $@
	@echo "        self.processed_dir = processed_dir" >> $@
	@echo "    def run_full_pipeline(self):" >> $@
	@echo "        print('Preprocessing placeholder')" >> $@

$(SRC)/data/feature_engineering.py:
	@mkdir -p $(SRC)/data
	@echo "# Feature engineering module" > $@
	@echo "class FeatureEngineer:" >> $@
	@echo "    def __init__(self, data_dir, config_file):" >> $@
	@echo "        self.data_dir = data_dir" >> $@
	@echo "    def generate_all_features(self):" >> $@
	@echo "        print('Feature engineering placeholder')" >> $@
	@echo "    def save_feature_matrix(self, output_path):" >> $@
	@echo "        print(f'Saving to {output_path}')" >> $@

$(SRC)/models/border_model.py:
	@mkdir -p $(SRC)/models
	@echo "# Border change model module" > $@
	@echo "class ModelTrainer:" >> $@
	@echo "    def __init__(self, config_file):" >> $@
	@echo "        self.config_file = config_file" >> $@
	@echo "    def load_data(self, data_path):" >> $@
	@echo "        print(f'Loading data from {data_path}')" >> $@
	@echo "    def train_all_models(self):" >> $@
	@echo "        print('Training models placeholder')" >> $@
	@echo "    def save_results(self, output_path):" >> $@
	@echo "        print(f'Saving results to {output_path}')" >> $@
	@echo "    def save_feature_importance(self, output_path):" >> $@
	@echo "        print(f'Saving feature importance to {output_path}')" >> $@

$(SRC)/models/validators.py:
	@mkdir -p $(SRC)/models
	@echo "# Model validation module" > $@
	@echo "class ModelValidator:" >> $@
	@echo "    def __init__(self, config_file):" >> $@
	@echo "        self.config_file = config_file" >> $@
	@echo "    def load_models(self, model_path):" >> $@
	@echo "        print(f'Loading models from {model_path}')" >> $@
	@echo "    def run_cross_validation(self):" >> $@
	@echo "        print('Cross-validation placeholder')" >> $@
	@echo "    def save_validation_results(self, output_path):" >> $@
	@echo "        print(f'Saving validation results to {output_path}')" >> $@

$(SRC)/analysis/exploratory.py:
	@mkdir -p $(SRC)/analysis
	@echo "# Exploratory analysis module" > $@
	@echo "class AnalysisRunner:" >> $@
	@echo "    def __init__(self, data_dir, output_dir):" >> $@
	@echo "        self.data_dir = data_dir" >> $@
	@echo "        self.output_dir = output_dir" >> $@
	@echo "    def run_full_analysis(self):" >> $@
	@echo "        print('Analysis placeholder')" >> $@
	@echo "    def generate_insights(self, output_path):" >> $@
	@echo "        print(f'Saving insights to {output_path}')" >> $@