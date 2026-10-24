import base64
import unittest
from fastapi import HTTPException
import main
import app_security as security
from office_modules import Entry, Document, Settings

def endpoint(name):return next(r.endpoint for r in main.app.routes if r.path.startswith('/api/workspace/') and r.endpoint.__name__==name)
class WorkspaceTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.a={'id':'office-a','name':'Synthetic office','lawyer_name':'Synthetic lawyer','is_active':True,'is_demo':False,'_persistent':True,'trial_end':'2030-01-01T00:00:00','data':{'cases':[]}}
        self.b={**self.a,'id':'office-b','data':{'cases':[]}}
        self.token=security.REQUEST_STATE.set({'office':self.a})
    async def asyncTearDown(self):security.REQUEST_STATE.reset(self.token)
    async def test_records_are_scoped_to_session(self):
        row=await endpoint('add_entry')('bailiffs',Entry(title='Synthetic notice',date='2026-10-25'))
        self.assertEqual(len((await endpoint('list_entries')('bailiffs'))['items']),1)
        security.REQUEST_STATE.get()['office']=self.b
        self.assertEqual((await endpoint('list_entries')('bailiffs'))['items'],[])
        with self.assertRaises(HTTPException):await endpoint('archive_entry')('bailiffs',row['item']['id'])
    async def test_document_download_is_private_and_validated(self):
        content=base64.b64encode(b'private synthetic test').decode()
        row=await endpoint('upload_document')(Document(name='test.txt',mime='text/plain',content=content))
        response=await endpoint('download')(row['id']);self.assertEqual(response.body,b'private synthetic test')
        security.REQUEST_STATE.get()['office']=self.b
        with self.assertRaises(HTTPException):await endpoint('download')(row['id'])
        with self.assertRaises(HTTPException):await endpoint('upload_document')(Document(name='fake.pdf',mime='application/pdf',content=content))
    async def test_settings_and_csv_never_claim_unsaved_success(self):
        await endpoint('save_settings')(Settings(office_name='Updated office',lawyer_name='Synthetic lawyer'))
        self.assertEqual((await endpoint('settings')())['settings']['office_name'],'Updated office')
        self.a['data']['cases']=[{'number':'=unsafe_formula','court':'Test'}]
        csv=(await endpoint('export_cases')()).body.decode()
        self.assertIn("'=unsafe_formula",csv)
