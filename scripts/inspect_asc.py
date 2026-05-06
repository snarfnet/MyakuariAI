import time

import jwt
import requests

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
BUNDLE_ID = 'com.tokyonasu.myakuariai'
APP_VERSION = '1.0.1'

p8 = open('/tmp/asc_key.p8').read()


def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )


def headers():
    return {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}


def api(method, path, **kwargs):
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=headers(), **kwargs)


def api_json(method, path, **kwargs):
    r = api(method, path, **kwargs)
    try:
        body = r.json()
    except Exception:
        body = {}
    return r, body


def list_all(path):
    all_data = []
    next_path = path
    while next_path:
        r, body = api_json('GET', next_path)
        print(f'GET {next_path}: {r.status_code}')
        if r.status_code != 200:
            print(r.text[:1000])
            return all_data
        all_data.extend(body.get('data', []))
        next_url = body.get('links', {}).get('next')
        next_path = next_url.split('/v1', 1)[1] if next_url else None
    return all_data


r, body = api_json('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')
app_id = body['data'][0]['id']
print(f'App ID: {app_id}')

versions = list_all(f'/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200')
for version in versions:
    attrs = version.get('attributes', {})
    if attrs.get('versionString') == APP_VERSION:
        version_id = version['id']
        print(f'Version {APP_VERSION}: id={version_id} state={attrs.get("appStoreState")}')
        r, build_body = api_json('GET', f'/appStoreVersions/{version_id}/build')
        print(f'  Build relationship: {r.status_code} {build_body}')
        locs = list_all(f'/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200')
        for loc in locs:
            la = loc.get('attributes', {})
            print(f'  Localization {la.get("locale")}: whatsNew={bool(la.get("whatsNew"))}')

print('Review submissions:')
subs = list_all(f'/apps/{app_id}/reviewSubmissions?limit=200')
for sub in subs:
    sid = sub['id']
    attrs = sub.get('attributes', {})
    print(f'  Submission {sid}: state={attrs.get("state")} submittedDate={attrs.get("submittedDate")}')
    r, items_body = api_json('GET', f'/reviewSubmissions/{sid}/items?include=appStoreVersion&limit=200')
    print(f'    Items: {r.status_code}')
    if r.status_code != 200:
        print(f'    {items_body}')
        continue
    for item in items_body.get('data', []):
        rel = item.get('relationships', {}).get('appStoreVersion', {}).get('data')
        print(f'    Item {item["id"]}: appStoreVersion={rel}')
