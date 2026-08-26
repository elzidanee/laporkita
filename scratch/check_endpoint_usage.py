import os
import json
import re

postman_file = 'scratch/backend/postman/LaporKita_QA_Collection.json'
with open(postman_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

def extract_items(items, folder_name=''):
    endpoints = []
    for item in items:
        if 'item' in item:
            subfolder = f"{folder_name} > {item['name']}" if folder_name else item['name']
            endpoints.extend(extract_items(item['item'], subfolder))
        elif 'request' in item:
            req = item['request']
            method = req.get('method', 'GET')
            url_obj = req.get('url', {})
            if isinstance(url_obj, dict):
                raw_path = '/' + '/'.join(url_obj.get('path', []))
            else:
                raw_path = str(url_obj)
            endpoints.append({
                'folder': folder_name,
                'name': item.get('name', ''),
                'method': method,
                'path': raw_path
            })
    return endpoints

endpoints = extract_items(data.get('item', []))

# Collect all dart file text in lib/
lib_code = ""
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as df:
                lib_code += df.read() + "\n"

# Check usage for distinct endpoint paths
distinct_endpoints = {}
for ep in endpoints:
    # normalize path key e.g. /api/v1/auth/login
    # convert {{param}} or :param to placeholder
    clean_path = re.sub(r'\{\{\w+\}\}', ':param', ep['path'])
    key = f"{ep['method']} {clean_path}"
    if key not in distinct_endpoints:
        distinct_endpoints[key] = ep

print(f"Total Unique Endpoints in Postman: {len(distinct_endpoints)}")
print("="*60)

used_count = 0
unused_count = 0

for key, ep in distinct_endpoints.items():
    method = ep['method']
    path = ep['path']
    
    # Extract path segment to search in dart code
    # e.g. /api/v1/auth/login -> 'auth/login' or '/auth/login'
    # e.g. /api/v1/reports/{{reportId}}/support -> 'reports' and 'support'
    path_segments = [seg for seg in path.split('/') if seg and seg != 'api' and seg != 'v1']
    
    # Build search pattern
    is_used = False
    
    # Direct substring search of key path parts
    if clean_path in lib_code:
        is_used = True
    else:
        # Check by clean endpoint pattern
        if len(path_segments) == 1:
            seg = path_segments[0]
            if f"'{seg}'" in lib_code or f"/{seg}" in lib_code or f"'{seg}/" in lib_code:
                is_used = True
        elif len(path_segments) >= 2:
            seg0 = path_segments[0]
            seg1 = path_segments[1]
            if not seg1.startswith('{{') and not seg1.startswith(':'):
                if f"{seg0}/{seg1}" in lib_code or f"{seg0}." in lib_code or f"/{seg0}" in lib_code:
                    # check if seg1 is also in code
                    if seg1 in lib_code:
                        is_used = True
            else:
                # e.g. /reports/:id or /users/:id
                if f"/{seg0}/" in lib_code or f"'{seg0}/" in lib_code or f"'{seg0}'" in lib_code:
                    if len(path_segments) > 2:
                        seg2 = path_segments[2]
                        if seg2 in lib_code:
                            is_used = True
                    else:
                        is_used = True

    status_str = "USED" if is_used else "NOT FOUND / UNUSED IN FRONTEND"
    if is_used:
        used_count += 1
    else:
        unused_count += 1

    print(f"[{status_str}] {method} {path} ({ep['folder']})")

print("="*60)
print(f"Summary: {used_count} used in frontend, {unused_count} not directly found/unused in frontend.")
