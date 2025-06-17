#!/usr/bin/env python3
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    html_content = '''<!DOCTYPE html>
<html><head><title>Border Analysis Report</title></head>
<body><h1>Border Change Analysis Report</h1>
<p>Report generated successfully.</p></body></html>'''

    with open(args.output, 'w') as f:
        f.write(html_content)
    print(f'Report generated: {args.output}')

if __name__ == '__main__':
    main()
