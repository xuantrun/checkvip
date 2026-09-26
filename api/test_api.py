import os
import sys
import unittest
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(BASE_DIR)
sys.path.insert(0, PARENT_DIR)
sys.path.insert(0, BASE_DIR)

import db_manager
from api_server import app

class TestAPI(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.headers = {
            'X-API-Key': 'REGMOD-PRO-2026-VIP',
            'X-Device-HWID': 'TEST-DEVICE-01'
        }

    def test_health(self):
        res = self.client.get('/api/v1/health')
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data['status'], 'online')

    def test_gun_status(self):
        res = self.client.get('/api/v1/gun/status')
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data['success'])
        self.assertIn('fft', data['data']['versions'])

    def test_gun_build_unauthorized(self):
        # Without key should fail with 403
        payload = {"version": "fft", "mode": "mod"}
        res = self.client.post('/api/v1/gun/build', json=payload)
        self.assertEqual(res.status_code, 403)

    def test_gun_build_authorized(self):
        payload = {
            "version": "fft",
            "mode": "mod",
            "options": {
                "outline_color": [255, 255, 0, 1.0],
                "xray_color": [255, 255, 255, 1.0],
                "outline_width": 2.0
            }
        }
        res = self.client.post('/api/v1/gun/build', json=payload, headers=self.headers)
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data['success'])
        self.assertIn('build_id', data)

        # Test download
        dl_res = self.client.get(f"/api/v1/gun/download/{data['build_id']}")
        self.assertEqual(dl_res.status_code, 200)
        self.assertGreater(len(dl_res.data), 1000000)

    def test_hitbox_info(self):
        res = self.client.get('/api/v1/hitbox/info')
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data['success'])
        self.assertEqual(data['base_size'], 63056)

    def test_hitbox_build(self):
        payload = {
            "params": {
                "male_head": {
                    "radius": 0.09908871,
                    "height": 0.12749058,
                    "centerX": -0.01061450,
                    "centerY": 0.0,
                    "centerZ": 0.0
                }
            }
        }
        res = self.client.post('/api/v1/hitbox/build', json=payload, headers=self.headers)
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertTrue(data['success'])
        self.assertIn('build_id', data)

        # Test download
        dl_res = self.client.get(f"/api/v1/hitbox/download/{data['build_id']}")
        self.assertEqual(dl_res.status_code, 200)
        self.assertEqual(len(dl_res.data), 63056)

if __name__ == '__main__':
    unittest.main()
