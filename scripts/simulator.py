import json
import subprocess

state = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))
candidates = [(runtime, device) for runtime, devices in state['devices'].items() if 'iOS' in runtime for device in devices if device['name'].startswith('iPhone')]
if not candidates:
    raise SystemExit('Kullanılabilir iPhone simülatörü yok.')
candidates.sort(key=lambda pair: (pair[0], 'Pro Max' in pair[1]['name'], pair[1]['name']), reverse=True)
print('SIMULATOR_ID=' + candidates[0][1]['udid'])
