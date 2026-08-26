import os
import json

postman_file = 'scratch/ai-service/AI_Service_LaporKita.postman_collection.json'
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

print(f"Total AI Service Postman Endpoints: {len(endpoints)}")
print("="*60)
for idx, ep in enumerate(endpoints, 1):
    print(f"{idx}. [{ep['method']}] {ep['path']} | Folder: {ep['folder']} | Name: {ep['name']}")
