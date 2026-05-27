import json
import sys
import uuid
from urllib.parse import urlparse

# Define standard headers to parameterize
HEADER_VARIABLES = {
    'host': 'HOST',
    'x-token': 'X_TOKEN',
    'x-app-context': 'X_APP_CONTEXT',
    'x-platform-version': 'X_PLATFORM_VERSION',
    'x-platform': 'X_PLATFORM',
    'x-app': 'X_APP',
    'x-app-version': 'X_APP_VERSION'
}

def create_postman_collection_and_env(har_path, requests_list_path, collection_out_path, env_out_path):
    # 1. Load HAR and Unique Requests
    print("Loading HAR file...")
    try:
        with open(har_path, 'r', encoding='utf-8') as f:
            har_data = json.load(f)
    except Exception as e:
        print(f"Error reading HAR file: {e}")
        return

    print("Loading requests list...")
    unique_requests = []
    try:
        with open(requests_list_path, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split(maxsplit=1)
                if len(parts) == 2:
                    unique_requests.append((parts[0], parts[1]))
    except Exception as e:
        print(f"Error reading requests list: {e}")
        return

    # 2. Setup Postman Structures
    collection = {
        "info": {
            "name": "RocketPay API Collection (Pre-Migration)",
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        "item": []
    }
    
    env_values = {}
    
    entries = har_data.get('log', {}).get('entries', [])
    print(f"Found {len(entries)} entries in HAR.")

    # 3. Helper to organize folders
    def get_folder(path_parts, current_folder_list):
        if not path_parts:
            return current_folder_list
            
        part = path_parts[0]
        # Find if folder exists
        for item in current_folder_list:
            if item.get('name') == part and 'item' in item:
                return get_folder(path_parts[1:], item['item'])
                
        # Create folder if it doesn't exist
        new_folder = {
            "name": part,
            "item": []
        }
        current_folder_list.append(new_folder)
        return get_folder(path_parts[1:], new_folder['item'])

    # 4. Group HAR entries by unique request signature
    grouped_entries = {}
    for entry in entries:
        req = entry.get('request', {})
        method = req.get('method', '')
        url = req.get('url', '')
        if not url:
            continue
            
        parsed_url = urlparse(url)
        path = parsed_url.path if parsed_url.path else "/"
        if len(path) > 1 and path.endswith('/'):
            path = path.rstrip('/')
            
        # Also store the host for the environment
        if 'HOST' not in env_values and parsed_url.netloc:
             env_values['HOST'] = parsed_url.netloc
            
        query_params = req.get('queryString', [])
        norm_query = sorted([(q.get('name', ''), q.get('value', '')) for q in query_params])
        query_tuple = tuple(norm_query)
        
        display_query = ""
        if norm_query:
             display_query = "?" + "&".join([f"{n}={v}" for n, v in norm_query])
             
        signature = f"{method} {path}{display_query}"
        
        # Capture environment variables from headers
        for h in req.get('headers', []):
            lower_name = h.get('name', '').lower()
            if lower_name in HEADER_VARIABLES and HEADER_VARIABLES[lower_name] not in env_values:
                # only use non-empty values
                val = h.get('value', '')
                if val:
                     env_values[HEADER_VARIABLES[lower_name]] = val
        
        if signature not in grouped_entries:
            grouped_entries[signature] = []
        grouped_entries[signature].append(entry)

    # 5. Process Each Unique Request
    print("Processing requests and writing to collection...")
    for target_method, target_url in unique_requests:
        target_signature = f"{target_method} {target_url}"
        matching_entries = grouped_entries.get(target_signature, [])
        
        if not matching_entries:
            # print(f"Warning: No HAR entries found for {target_signature}")
            continue
            
        parsed_target = urlparse(target_url)
        path_parts = [p for p in parsed_target.path.split('/') if p]
        if not path_parts:
            path_parts = ["/"]
            
        target_folder_list = get_folder(path_parts[:-1], collection['item'])
        item_name = path_parts[-1] if path_parts[-1] != "/" else "/"
        
        # Create the main item based on the FIRST matching entry
        first_entry = matching_entries[0]
        first_req = first_entry.get('request', {})
        
        pm_headers = []
        for h in first_req.get('headers', []):
            name = h.get('name', '')
            val = h.get('value', '')
            # Skip pseudo-headers normally excluded in Postman
            if name.startswith(':'):
                continue
            
            # Parametrize
            lower_name = name.lower()
            if lower_name == 'host':
                val = '{{HOST}}'
            elif lower_name in HEADER_VARIABLES:
                val = f"{{{{{HEADER_VARIABLES[lower_name]}}}}}"
                
            pm_headers.append({
                "key": name,
                "value": val
            })
            
        pm_url = {
            "raw": f"https://{{{{HOST}}}}{parsed_target.path}{('?' + parsed_target.query) if parsed_target.query else ''}",
            "protocol": "https",
            "host": ["{{HOST}}"],
            "path": parsed_target.path.strip('/').split('/'),
            "query": [{"key": q.get('name'), "value": q.get('value')} for q in first_req.get('queryString', [])]
        }
        
        pm_body = {}
        if first_req.get('postData', {}).get('text'):
            pm_body = {
                "mode": "raw",
                "raw": first_req['postData']['text'],
                "options": {
                    "raw": {
                        "language": "json"
                    }
                }
            }
            
        pm_item = {
            "name": item_name,
            "request": {
                "method": target_method,
                "header": pm_headers,
                "url": pm_url,
            },
            "response": []
        }
        
        if pm_body:
            pm_item["request"]["body"] = pm_body

        # Add all examples
        for idx, entry in enumerate(matching_entries):
            req = entry.get('request', {})
            res = entry.get('response', {})
            
            # Same headers, url, body mapped logic for the example's original HTTP request
            ex_req_headers = [{"key": h.get("name"), "value": h.get("value")} for h in req.get("headers", []) if not h.get("name", "").startswith(":")]
            
            ex_body_raw = req.get('postData', {}).get('text', '')
            ex_res_body = res.get('content', {}).get('text', '')
            
            pm_item["response"].append({
                "name": f"Example {idx+1} - {res.get('status', 'Unknown')}",
                "originalRequest": {
                    "method": req.get('method'),
                    "header": ex_req_headers,
                    "url": {
                        "raw": req.get('url'),
                        "protocol": urlparse(req.get('url', '')).scheme,
                        "host": [urlparse(req.get('url', '')).netloc],
                        "path": urlparse(req.get('url', '')).path.strip('/').split('/'),
                        "query": [{"key": q.get('name'), "value": q.get('value')} for q in req.get('queryString', [])]
                    },
                    "body": {
                        "mode": "raw",
                        "raw": ex_body_raw
                    } if ex_body_raw else {}
                },
                "status": res.get('statusText', "OK"),
                "code": res.get('status', 200),
                "_postman_previewlanguage": "json",
                "header": [{"key": h.get("name"), "value": h.get("value")} for h in res.get("headers", [])],
                "cookie": [],
                "body": ex_res_body
            })
            
        target_folder_list.append(pm_item)

    # 6. Format Environment
    pm_environment = {
        "id": str(uuid.uuid4()),
        "name": "RocketPay Staging",
        "values": [
            {"key": k, "value": v, "type": "default", "enabled": True} for k, v in env_values.items()
        ]
    }

    # 7. Write to file
    with open(collection_out_path, 'w', encoding='utf-8') as f:
        json.dump(collection, f, indent=2)
    print(f"Collection saved to {collection_out_path}")
    
    with open(env_out_path, 'w', encoding='utf-8') as f:
        json.dump(pm_environment, f, indent=2)
    print(f"Environment saved to {env_out_path}")

if __name__ == "__main__":
    create_postman_collection_and_env(
        "transactions.har",
        "all-requests.txt",
        "rocketpay_collection.json",
        "rocketpay_env.json"
    )
