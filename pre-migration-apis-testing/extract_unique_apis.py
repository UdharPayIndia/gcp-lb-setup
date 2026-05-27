import json
import sys
from urllib.parse import urlparse

def extract_unique_requests(har_file_path):
    try:
        with open(har_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading HAR file: {e}", file=sys.stderr)
        return

    unique_requests = set()
    
    entries = data.get('log', {}).get('entries', [])
    for entry in entries:
        request = entry.get('request', {})
        method = request.get('method', 'UNKNOWN')
        url = request.get('url', '')
        
        if not url:
            continue
            
        parsed_url = urlparse(url)
        path = parsed_url.path
        if not path:
            path = "/"
            
        # Normalize path: remove trailing slash for consistency
        if len(path) > 1 and path.endswith('/'):
            path = path.rstrip('/')
            
        # Extract and normalize query parameters
        query_params = request.get('queryString', [])
        # Store as a sorted tuple of (name, value) for uniqueness
        norm_query = sorted([(q.get('name', ''), q.get('value', '')) for q in query_params])
        query_tuple = tuple(norm_query)
        
        # Uniqueness key: (Method, Path, QueryParams)
        # Note: Path params are inherently part of the path in HAR logs.
        unique_key = (method, path, query_tuple)
        
        if unique_key not in unique_requests:
            unique_requests.add(unique_key)
            
            # Format query string for display
            display_query = ""
            if norm_query:
                # We use the original query string order if possible for display?
                # Actually, sorted is safer for "unique" representation.
                display_query = "?" + "&".join([f"{n}={v}" for n, v in norm_query])
            
            print(f"{method:7} {path}{display_query}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_unique_apis.py <path_to_har_file>")
        sys.exit(1)
        
    extract_unique_requests(sys.argv[1])
