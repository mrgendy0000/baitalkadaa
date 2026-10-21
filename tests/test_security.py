import copy
import unittest
from unittest.mock import patch
from datetime import datetime, timedelta
from fastapi import HTTPException, Response
import app_security as security
import main

class SecurityTests(unittest.TestCase):
    def test_password_hash_salt_and_verification(self):
        a=security.hash_password('unit-test-password')
        b=security.hash_password('unit-test-password')
        self.assertNotEqual(a,b)
        self.assertTrue(security.verify_password('unit-test-password',a))
        self.assertFalse(security.verify_password('wrong-password',a))
        self.assertFalse(security.verify_password('test','invalid'))
    def test_password_policy(self):
        for pwd in ('','123456789','x'*129):
            with self.assertRaises(HTTPException): security.validate_password(pwd)
        security.validate_password('x'*10)
    def test_cookie_is_server_only(self):
        response=Response();security.set_session_cookie(response,'synthetic-test-cookie')
        value=response.headers['set-cookie']
        self.assertIn('HttpOnly',value);self.assertIn('Secure',value);self.assertIn('SameSite=lax',value)
        self.assertIn('__Host-',value);self.assertNotIn('Domain=',value)
    def test_persist_uses_office_and_version_and_rejects_conflict(self):
        office={'id':'a-test-office','_persistent':True,'_version':3,'data':{'cases':[{'id':'c'}]}}
        with patch.object(security,'_execute',return_value=[[],[]]) as execute:
            with self.assertRaises(HTTPException) as error: security.persist(office,{'cases':[]})
            self.assertEqual(error.exception.status_code,409)
            query=execute.call_args[0][0][1]
            self.assertIn('office_id=$2::uuid AND version=$3',query['query'])
            self.assertEqual(query['params'][1:],['a-test-office',3])
    def test_unchanged_office_does_not_write(self):
        office={'_persistent':True,'data':{'cases':[]}}
        with patch.object(security,'_execute') as execute:
            security.persist(office,copy.deepcopy(office['data']));execute.assert_not_called()
    def test_session_token_is_hashed_and_revocable(self):
        with patch.object(security,'query') as query:
            token=security.create_session('office-uuid')
            params=query.call_args[0][1]
            self.assertNotEqual(token,params[0]);self.assertEqual(len(params[0]),64)
            with patch.object(security,'configured',return_value=True): security.end_session(token)
            self.assertIn('DELETE',query.call_args[0][0])
            self.assertEqual(query.call_args[0][1][0],params[0])
    def test_demo_and_expired_office_cannot_write(self):
        for office in (main.resolve_office('token_demo'),{'is_active':True,'trial_end':(datetime.utcnow()-timedelta(days=1)).isoformat()}):
            with self.assertRaises(HTTPException) as error: main.check_trial_permission(office,True)
            self.assertEqual(error.exception.status_code,403)
    def test_office_context_prevents_spoofing(self):
        office={'id':'real-session-office'}
        token=security.REQUEST_STATE.set({'office':office})
        try: self.assertIs(main.resolve_office('office_super_admin'),office)
        finally: security.REQUEST_STATE.reset(token)
    def test_profile_never_leaks_password_or_internal_state(self):
        row=dict(id='id',name='Office',lawyer_name='Lawyer',email='qa@example.invalid',phone='00000000',is_active=True,is_admin=False,plan='trial',created_at='2026-10-21T00:00:00+00:00',trial_start='2026-10-21T00:00:00+00:00',trial_end='2026-11-21T00:00:00+00:00',password_hash='synthetic-hash')
        office=security.profile(row);self.assertNotIn('password_hash',office)
        response=security.session_response(office)
        self.assertEqual(response['token'],'cookie_session');self.assertNotIn('_persistent',response['office'])

class RouteSecurityTests(unittest.IsolatedAsyncioTestCase):
    async def test_public_trial_renewal_disabled(self):
        with self.assertRaises(HTTPException) as error: await main.disabled_trial_test()
        self.assertEqual(error.exception.status_code,403)
    async def test_guest_cannot_open_admin(self):
        with self.assertRaises(HTTPException) as error: await main.get_admin_overview('token_demo',None)
        self.assertEqual(error.exception.status_code,403)
