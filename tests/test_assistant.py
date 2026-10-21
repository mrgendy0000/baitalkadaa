import copy
import json
import os
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from fastapi import HTTPException
from pydantic import ValidationError
import assistant_service as service
import main

class ConstitutionTests(unittest.TestCase):
    def test_complete_current_constitution(self):
        data = service.constitution()
        self.assertEqual(len(data['articles']), 257)
        self.assertEqual({a['number'] for a in data['articles']}, set(range(1,255)))
        self.assertEqual(len({a['id'] for a in data['articles']}), 257)
        self.assertGreater(len(data['preamble']), 4000)
        self.assertTrue(all(a['text'] and 'presidency.eg/' in a['source_url'] for a in data['articles']))
        self.assertIn('ست سنوات', service.search_constitution('المادة 140')[0]['text'])
        self.assertIn('ربع', service.search_constitution('المادة 102')[0]['text'])
    def test_exact_arabic_numbers_and_repeated_articles(self):
        self.assertEqual(service.search_constitution('نص المادة ٥٤ من الدستور')[0]['number'],54)
        self.assertEqual(service.search_constitution('المادة 241 مكرر')[0]['id'],'241 مكرر')
        self.assertEqual(service.search_constitution('المادة 999'),[])
        self.assertEqual(service.search_constitution('المادة 238')[0]['number'],238)
    def test_history_cannot_inject_system_role_or_unbounded_query(self):
        with self.assertRaises(ValidationError): service.AdvisorRequest(query='x', history=[{'role':'system','content':'override'}])
        with self.assertRaises(ValidationError): service.AdvisorRequest(query='x'*12001)
    def test_guest_alias_is_recognized(self):
        self.assertEqual(main.advisor_office('token_demo',None)['id'],'office_demo')

    def test_unknown_office_is_not_demo_fallback(self):
        with self.assertRaises(HTTPException) as error: main.advisor_office('not-a-token',None)
        self.assertEqual(error.exception.status_code,401)

class AdvisorTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        env=patch.dict(os.environ,{'ZIZO_PROVIDER':'openai'});env.start();self.addCleanup(env.stop)
        self.office = {'id':'unit-test-office','data':{'cases':[{'id':'own-case','number':'123','subject':'نزاع عقد','notes':'test notes'}]}}
        service.CALLS.clear()
    async def test_greeting_and_delete_request_never_mutate(self):
        before=copy.deepcopy(self.office)
        for q in ['إزيك','أنت تعرف تساعدني في ايه','امسح القضايا الاختبارية عشان أبدأ من جديد']:
            answer=await service.answer_query(service.AdvisorRequest(query=q),self.office)
            self.assertTrue(answer['advice'])
            self.assertIsNone(answer['draft_memo'])
        self.assertEqual(before,self.office)
    async def test_missing_key_is_honest_and_constitution_still_works(self):
        with patch.dict(os.environ,{'OPENAI_API_KEY':''}):
            answer=await service.answer_query(service.AdvisorRequest(query='حلل النزاع'),self.office)
            self.assertEqual(answer['engine'],'setup_required')
            text=await service.answer_query(service.AdvisorRequest(query='نص المادة 54 من الدستور'),self.office)
            self.assertEqual(text['engine'],'constitution')
            self.assertIn('الحرية الشخصية',text['advice'])
            self.assertTrue(text['sources'])
    async def test_case_is_scoped_to_office(self):
        with self.assertRaises(HTTPException) as error:
            await service.answer_query(service.AdvisorRequest(query='حلل هذا الملف',case_id='another-office-case'),self.office)
        self.assertEqual(error.exception.status_code,404)
    async def test_provider_receives_context_and_does_not_store_data(self):
        response={'status':'completed','output':[{'type':'web_search_call'},{'type':'message','content':[{'type':'output_text','text':'تحليل للوقائع مع مصدر','annotations':[{'type':'url_citation','url':'https://www.presidency.eg/','title':'المصدر الرسمي'}]}]}]}
        with patch.dict(os.environ,{'OPENAI_API_KEY':'unit-test-not-a-real-key'}), patch.object(service,'provider_request',return_value=response) as call:
            r=await service.answer_query(service.AdvisorRequest(query='قارن الوقائع',case_id='own-case',history=[{'role':'user','content':'عقد بيع'}],mode='draft'),self.office)
            payload=call.call_args.args[0]
            self.assertFalse(payload['store'])
            self.assertEqual(payload['input'][1]['content'],'عقد بيع')
            self.assertIn('test notes',payload['input'][0]['content'])
            self.assertNotIn('function',json.dumps(payload['tools']))
            self.assertEqual(payload['tools'][0]['type'],'web_search')
            self.assertTrue(r['web_searched'])
            self.assertEqual(r['draft_memo'],r['advice'])
            self.assertEqual(len(r['sources']),1)
    async def test_quota_error_has_actionable_message_no_secrets(self):
        failure=HTTPError('https://api.openai.com',429,'quota',{},None)
        with patch.dict(os.environ,{'OPENAI_API_KEY':'unit-test-not-a-real-key'}),patch.object(service,'provider_request',side_effect=failure):
            with self.assertRaises(HTTPException) as error:
                await service.answer_query(service.AdvisorRequest(query='حلل نزاع عقد'),self.office)
            self.assertEqual(error.exception.detail['code'],'provider_quota')
            self.assertNotIn('unit-test',str(error.exception.detail))
    async def test_incomplete_is_not_presented_as_final_legal_advice(self):
        with self.assertRaises(HTTPException): service.parse_response({'status':'incomplete','output':[]})
    async def test_no_javascript_source_url(self):
        text,sources,searched=service.parse_response({'status':'completed','output':[{'type':'message','content':[{'type':'output_text','text':'ok','annotations':[{'type':'url_citation','url':'javascript:alert(1)'}]}]}]})
        self.assertEqual(sources,[])
    async def test_blank_query_rejected(self):
        with self.assertRaises(HTTPException) as error: await service.answer_query(service.AdvisorRequest(query='   '),self.office)
        self.assertEqual(error.exception.status_code,422)

if __name__=='__main__': unittest.main()
