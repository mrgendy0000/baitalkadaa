"""Authenticated office operations, stored under the existing isolated office state."""
import base64
import binascii
import csv
import io
from datetime import datetime
from typing import Literal
from uuid import uuid4
from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel, Field

router=APIRouter(prefix='/api/workspace')
class Entry(BaseModel):
    title: str=Field(min_length=1,max_length=180)
    reference: str=Field(default='',max_length=180)
    date: str=Field(default='',max_length=10)
    status: str=Field(default='pending',max_length=30)
    notes: str=Field(default='',max_length=4000)
class Document(BaseModel):
    name: str=Field(min_length=1,max_length=180)
    mime: Literal['application/pdf','image/png','image/jpeg','image/webp','text/plain']
    content: str=Field(max_length=1500000)
class Settings(BaseModel):
    office_name: str=Field(min_length=1,max_length=160)
    lawyer_name: str=Field(min_length=1,max_length=160)
    governorate: str=Field(default='',max_length=80)
    bar_number: str=Field(default='',max_length=80)
    notary_office: str=Field(default='',max_length=160)


def setup(resolve,check):
    def current(write=False):
        office=resolve();check(office,for_mutation=write);return office
    def collection(office,key):return office['data'].setdefault('workspace',{}).setdefault(key,[])
    @router.get('/{kind}')
    async def list_entries(kind: Literal['bailiffs','staff','documents']):
        values=collection(current(),kind)
        return {'items':[{k:v for k,v in row.items() if k!='content'} for row in values if not row.get('archived')]}
    @router.post('/{kind}')
    async def add_entry(kind: Literal['bailiffs','staff'],entry:Entry):
        office=current(True)
        if entry.date:
            try:datetime.strptime(entry.date,'%Y-%m-%d')
            except ValueError:raise HTTPException(422,detail='التاريخ غير صحيح.') from None
        values=collection(office,kind)
        if len(values)>=1000:raise HTTPException(409,detail='وصل السجل للحد المسموح. صدّر نسخة وراجع الدعم.')
        item={**entry.model_dump(),'id':uuid4().hex,'created_at':datetime.utcnow().isoformat()}
        values.insert(0,item);return {'item':item}
    @router.patch('/{kind}/{entry_id}')
    async def archive_entry(kind:Literal['bailiffs','staff','documents'],entry_id:str):
        values=collection(current(True),kind)
        item=next((v for v in values if v['id']==entry_id),None)
        if not item:raise HTTPException(404,detail='العنصر غير موجود في مكتبك.')
        item['archived']=not item.get('archived',False);return {'status':'success'}
    @router.post('/documents/upload')
    async def upload_document(doc:Document):
        office=current(True)
        try:raw=base64.b64decode(doc.content,validate=True)
        except (ValueError,binascii.Error):raise HTTPException(422,detail='محتوى الملف غير صحيح.') from None
        if not raw or len(raw)>1000000:raise HTTPException(413,detail='الحد الأقصى للملف 1 ميجابايت.')
        signatures={'application/pdf':b'%PDF-','image/png':b'\x89PNG\r\n\x1a\n','image/jpeg':b'\xff\xd8\xff'}
        if doc.mime in signatures and not raw.startswith(signatures[doc.mime]):raise HTTPException(422,detail='نوع الملف لا يطابق محتواه.')
        if doc.mime=='image/webp' and not(raw.startswith(b'RIFF') and raw[8:12]==b'WEBP'):raise HTTPException(422,detail='صورة WebP غير صحيحة.')
        if doc.mime=='text/plain':
            try:raw.decode('utf-8')
            except UnicodeDecodeError:raise HTTPException(422,detail='ملف النص يجب أن يكون UTF-8.') from None
        values=collection(office,'documents')
        if sum(v.get('size',0) for v in values)+len(raw)>5000000:raise HTTPException(413,detail='حد المستندات الحالي للمكتب 5 ميجابايت. التنزيل متاح للاحتفاظ بنسخة.')
        item={**doc.model_dump(),'id':uuid4().hex,'size':len(raw),'created_at':datetime.utcnow().isoformat()}
        values.insert(0,item);return {'id':item['id'],'status':'success'}
    @router.get('/documents/{document_id}/download')
    async def download(document_id:str):
        item=next((d for d in collection(current(),'documents') if d['id']==document_id and not d.get('archived')),None)
        if not item:raise HTTPException(404,detail='المستند غير موجود في مكتبك.')
        return Response(base64.b64decode(item['content']),media_type=item['mime'],headers={'Content-Disposition':'attachment; filename="legal-document"','X-Content-Type-Options':'nosniff','Cache-Control':'private, no-store'})
    @router.get('/settings/current')
    async def settings():
        office=current();data={'office_name':office['name'],'lawyer_name':office['lawyer_name'],'governorate':'','bar_number':'','notary_office':''}
        data.update(office['data'].get('workspace',{}).get('settings',{}));return {'settings':data}
    @router.put('/settings/current')
    async def save_settings(data:Settings):
        office=current(True);office['data'].setdefault('workspace',{})['settings']=data.model_dump();return {'status':'success','settings':data.model_dump()}
    @router.get('/reports/cases.csv')
    async def export_cases():
        office=current();out=io.StringIO();writer=csv.writer(out);writer.writerow(['رقم القضية','المحكمة','الموضوع','المرحلة','الجلسة القادمة'])
        def safe(value):
            value=str(value or '');return "'"+value if value.lstrip().startswith(('=','+','-','@')) else value
        for row in office['data'].get('cases',[]):writer.writerow([safe(row.get(k)) for k in ('number','court','subject','stage','next_session')])
        return Response('\ufeff'+out.getvalue(),media_type='text/csv; charset=utf-8',headers={'Content-Disposition':'attachment; filename="legal-cases.csv"','Cache-Control':'private, no-store'})
    return router
