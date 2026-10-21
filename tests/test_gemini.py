import unittest
from unittest.mock import patch
from fastapi import HTTPException
import assistant_service as service
import gemini_service as gemini

class GeminiTests(unittest.TestCase):
    def setUp(self):
        self.office={'id':'qa','name':'test office','lawyer_name':'test lawyer','data':{'cases':[],'clients':[{'name':'Known private client'}]}}
    def test_paid_key_does_not_enable_default_provider(self):
        with patch.dict('os.environ',{'ZIZO_PROVIDER':'gemini','OPENAI_API_KEY':'synthetic','GEMINI_API_KEY':''}):
            self.assertFalse(service.assistant_status()['configured'])
            self.assertEqual(service.selected_provider(),'gemini')
    def test_private_case_or_unconfirmed_query_never_leaves_server(self):
        for req in [service.AdvisorRequest(query='عام'),service.AdvisorRequest(query='عام',public_query=True,case_id='private')]:
            with self.assertRaises(HTTPException):gemini.build_payload(req,self.office,'instructions',[])
    def test_obvious_identifiers_and_known_clients_are_blocked(self):
        for text in ['contact qa@example.invalid','Known private client has a dispute','phone 000123456789']:
            with self.assertRaises(HTTPException):gemini.public_text(text,self.office)
    def test_only_public_history_and_general_reference_are_sent(self):
        req=service.AdvisorRequest(query='سؤال عام',public_query=True,history=[{'role':'user','content':'private history'},{'role':'assistant','content':'public history','public_query':True}],research=True)
        model,payload=gemini.build_payload(req,self.office,'instructions',[])
        self.assertEqual(model,'gemini-2.5-flash')
        self.assertNotIn('private history',str(payload));self.assertIn('public history',str(payload))
        self.assertEqual(payload['tools'],[{'google_search':{}}])
        self.assertNotIn('Known private client',str(payload))
    def test_grounded_sources_and_suggestions_are_preserved(self):
        data={'candidates':[{'finishReason':'STOP','content':{'parts':[{'text':'Fact'}]},'groundingMetadata':{'webSearchQueries':['public question'],'groundingChunks':[{'web':{'uri':'https://www.presidency.eg/','title':'Official'}}],'groundingSupports':[{'segment':{'text':'Fact'},'groundingChunkIndices':[0]}],'searchEntryPoint':{'renderedContent':'<div>Google Search</div>'}}}]}
        text,sources,searched,widget=gemini.parse_response(data,service.safe_url)
        self.assertIn('[Official]',text);self.assertTrue(searched);self.assertEqual(len(sources),1);self.assertIn('Google',widget)
    def test_partial_output_is_not_a_completed_legal_answer(self):
        with self.assertRaises(HTTPException):gemini.parse_response({'candidates':[{'finishReason':'MAX_TOKENS','content':{'parts':[{'text':'partial'}]}}]},service.safe_url)
