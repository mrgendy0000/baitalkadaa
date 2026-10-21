"""Server-only, durable Neon accounts and opaque HttpOnly sessions.
No client receives database credentials or session token bodies.
"""
import hashlib
import json
import os
import secrets
import threading
import time
from contextvars import ContextVar
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from uuid import uuid4, UUID

from fastapi import HTTPException

REQUEST_STATE = ContextVar('legal_request_state', default=None)
COOKIE = '__Host-legal_session'
LOCAL_COOKIE = 'legal_session_local'
_init_lock = threading.Lock()


def configured():
    return bool(os.environ.get('DATABASE_URL'))


def _decode_result(result):
    columns = result.get('fields', [])
    rows = []
    for values in result.get('rows', []):
        row = {}
        for field, value in zip(columns, values):
            kind = int(field.get('dataTypeID', 0))
            if value is not None:
                if kind in (114, 3802): value = json.loads(value) if isinstance(value,str) else value
                elif kind == 16: value = value in ('t','true',True)
                elif kind in (20,21,23): value = int(value)
            row[field['name']] = value
        rows.append(row)
    return rows


def _execute(queries):
    connection = os.environ.get('DATABASE_URL','')
    parsed = urlparse(connection)
    if parsed.scheme not in ('postgres','postgresql') or not parsed.hostname or not parsed.hostname.endswith('.neon.tech'):
        raise HTTPException(503, detail='قاعدة البيانات الآمنة غير مهيأة. راجع DATABASE_URL في الخادم.')
    endpoint = 'https://api.'+parsed.hostname.split('.',1)[1]+'/sql'
    req = Request(endpoint, data=json.dumps({'queries':queries}).encode(), headers={'Neon-Connection-String':connection,'Neon-Raw-Text-Output':'true','Neon-Array-Mode':'true','Neon-Batch-Isolation-Level':'Serializable','Content-Type':'application/json'}, method='POST')
    try:
        with urlopen(req, timeout=18) as response:
            data=json.load(response)
        return [_decode_result(r) for r in data['results']]
    except HTTPError as exc:
        # Only use SQLSTATE to classify expected errors. Never log query values/DSNs.
        try: code=json.loads(exc.read()).get('code')
        except (ValueError,TypeError): code=None
        if code=='23505': raise HTTPException(409, detail='البريد أو الهاتف مسجل بالفعل.') from None
        if code in ('40001','40P01'): raise HTTPException(409, detail='يوجد تحديث متزامن. أعد المحاولة بعد تحديث الصفحة.') from None
        raise HTTPException(503, detail='تعذر إتمام الاتصال الآمن بقاعدة البيانات. أعد المحاولة لاحقاً.') from None
    except (URLError,TimeoutError,OSError,ValueError,KeyError):
        raise HTTPException(503, detail='تعذر الاتصال بقاعدة البيانات. لم يتم تأكيد حفظ التغيير.') from None


def query(sql, params=None):
    return _execute([{'query':sql,'params':params or []}])[0]


@lru_cache(maxsize=1)
def ensure_schema():
    with _init_lock:
        source=(Path(__file__).parent/'security/schema.sql').read_text()
        commands=[{'query':'SELECT pg_advisory_xact_lock(20261021)','params':[]}]
        commands += [{'query':line.strip(),'params':[]} for line in source.split(';') if line.strip()]
        _execute(commands)
    return True


def initialize():
    if not configured(): raise HTTPException(503, detail='التسجيل متوقف لحين تفعيل قاعدة البيانات الآمنة؛ وضع الضيف متاح.')
    ensure_schema()


def hash_password(password):
    salt=secrets.token_bytes(16)
    digest=hashlib.pbkdf2_hmac('sha256',password.encode(),salt,600000,dklen=32)
    return 'pbkdf2_sha256$600000$'+salt.hex()+'$'+digest.hex()


def verify_password(password, encoded):
    try:
        method,n,salt,expected=encoded.split('$')
        if method!='pbkdf2_sha256' or n!='600000': return False
        digest=hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(salt),600000,dklen=32).hex()
        return secrets.compare_digest(digest,expected)
    except (ValueError,TypeError,AttributeError): return False


def validate_password(password):
    if not password or len(password)<10 or len(password)>128:
        raise HTTPException(422, detail='كلمة المرور لازم تكون من 10 إلى 128 حرفاً.')


def _iso(value):
    if isinstance(value,str):
        return datetime.fromisoformat(value.replace('Z','+00:00')).astimezone(timezone.utc).replace(tzinfo=None).isoformat()
    return value


def profile(row):
    # An explicit allow-list prevents password hashes leaking from auth queries.
    result={k:row[k] for k in ('id','name','lawyer_name','email','phone','is_active','is_admin','plan')}
    result.update({k:_iso(row[k]) for k in ('created_at','trial_start','trial_end')})
    result['is_demo']=False
    result['_persistent']=True
    return result


def _context_queries(office_id, sql, params=None):
    return [{'query':"SELECT set_config('legal.office_id',$1,true)",'params':[office_id]}, {'query':sql,'params':params or []}]


def read_state(office_id):
    rows=_execute(_context_queries(office_id,'SELECT data,version FROM legal_private.state WHERE office_id=$1::uuid',[office_id]))[1]
    if not rows: raise HTTPException(503, detail='ملف المكتب غير متاح. تواصل مع الدعم.')
    return rows[0]


def load_session(token):
    initialize()
    hashed=hashlib.sha256(token.encode()).hexdigest()
    rows=query('SELECT o.* FROM legal_private.sessions s JOIN legal_private.offices o ON o.id=s.office_id WHERE s.token_hash=$1 AND s.expires_at>now()',[hashed])
    if not rows: raise HTTPException(401, detail='الجلسة انتهت أو غير صالحة. سجّل الدخول مجدداً.')
    office=profile(rows[0])
    if not office['is_active']: raise HTTPException(403, detail='حساب المكتب موقوف؛ تواصل مع الإدارة.')
    state=read_state(office['id'])
    office['data']=state['data'];office['_version']=state['version']
    return office


def persist(office, original):
    if not office.get('_persistent') or office['data']==original: return
    rows=_execute(_context_queries(office['id'], 'UPDATE legal_private.state SET data=$1::jsonb,version=version+1,updated_at=now() WHERE office_id=$2::uuid AND version=$3 RETURNING version',[json.dumps(office['data'],ensure_ascii=False),office['id'],office['_version']]))[1]
    if not rows: raise HTTPException(409, detail='تغيّر ملف المكتب في جلسة أخرى. حدّث الصفحة وأعد الإجراء.')


def reserve(bucket, limit, window=60):
    initialize()
    key=hashlib.sha256((str(int(time.time()//window))+':'+bucket).encode()).hexdigest()
    rows=query('INSERT INTO legal_private.limits(bucket) VALUES ($1) ON CONFLICT(bucket) DO UPDATE SET count=legal_private.limits.count+1 WHERE legal_private.limits.count<$2 RETURNING count',[key,limit])
    if not rows: raise HTTPException(429, detail='وصلت للحد المسموح من الطلبات. حاول بعد قليل.')


def create_session(office_id):
    token=secrets.token_urlsafe(32)
    query('INSERT INTO legal_private.sessions(token_hash,office_id) VALUES ($1,$2::uuid)',[hashlib.sha256(token.encode()).hexdigest(),office_id])
    return token


def register_account(req, empty_data):
    initialize();validate_password(req.password)
    email=req.email.strip().lower();phone=req.phone.strip()
    if '@' not in email or len(email)>254: raise HTTPException(422, detail='اكتب بريدك الإلكتروني الصحيح لتسجيل المكتب.')
    if len(phone)<8 or len(phone)>24: raise HTTPException(422, detail='اكتب رقم هاتف صحيحاً.')
    for value in (req.office_name,req.lawyer_name):
        if not value.strip() or len(value)>160: raise HTTPException(422, detail='اسم المكتب والمحامي مطلوب وبحد أقصى 160 حرفاً.')
    office_id=str(uuid4())
    commands=_context_queries(office_id,'INSERT INTO legal_private.offices(id,email,phone,password_hash,name,lawyer_name) VALUES ($1::uuid,$2,$3,$4,$5,$6) RETURNING *',[office_id,email,phone,hash_password(req.password),req.office_name.strip(),req.lawyer_name.strip()])
    commands.append({'query':'INSERT INTO legal_private.state(office_id,data) VALUES ($1::uuid,$2::jsonb)','params':[office_id,json.dumps(empty_data)]})
    rows=_execute(commands)[1]
    return profile(rows[0]),create_session(office_id)


def login_account(identifier,password):
    initialize()
    identifier=identifier.strip().lower()
    rows=query('SELECT * FROM legal_private.offices WHERE email=$1 OR phone=$1 LIMIT 1',[identifier])
    # Perform a KDF even on unknown accounts to reduce a timing distinction.
    encoded=rows[0]['password_hash'] if rows else 'pbkdf2_sha256$600000$'+'00'*16+'$'+'00'*32
    valid=verify_password(password or '',encoded)
    if not rows or not valid: raise HTTPException(401, detail='بيانات الدخول غير صحيحة.')
    if not rows[0]['is_active']: raise HTTPException(403, detail='حساب المكتب موقوف؛ تواصل مع الإدارة.')
    return profile(rows[0]),create_session(rows[0]['id'])


def end_session(token):
    if token and configured(): query('DELETE FROM legal_private.sessions WHERE token_hash=$1',[hashlib.sha256(token.encode()).hexdigest()])


def set_session_cookie(response,token,secure=True):
    response.set_cookie(COOKIE if secure else LOCAL_COOKIE,token,max_age=7*86400,httponly=True,secure=secure,samesite='lax',path='/')
    response.headers['Cache-Control']='private, no-store'


def clear_session_cookie(response):
    response.delete_cookie(COOKIE,path='/',secure=True,httponly=True,samesite='lax')
    response.delete_cookie(LOCAL_COOKIE,path='/',httponly=True,samesite='lax')


def session_response(office):
    tend=datetime.fromisoformat(office['trial_end']);now=datetime.utcnow()
    value={k:v for k,v in office.items() if not k.startswith('_') and k!='data'}
    value.update({'days_remaining':max(0,(tend-now).days),'hours_remaining':max(0,int((tend-now).total_seconds()/3600)),'is_expired':now>tend,'office_name':office['name']})
    return {'status':'success','token':'cookie_session','is_admin':bool(office['is_admin']),'role':'super_admin' if office['is_admin'] else 'lawyer','office':value}


def list_offices():
    initialize()
    return [profile(row) for row in query('SELECT * FROM legal_private.offices ORDER BY created_at DESC LIMIT 500')]


def get_office(office_id):
    initialize()
    try: office_id=str(UUID(office_id))
    except ValueError: raise HTTPException(404,detail='المكتب غير موجود.') from None
    rows=query('SELECT * FROM legal_private.offices WHERE id=$1::uuid',[office_id])
    if not rows: raise HTTPException(404,detail='المكتب غير موجود.')
    return profile(rows[0])


def update_subscription(office):
    query('UPDATE legal_private.offices SET trial_end=$1::timestamptz,is_active=$2,plan=$3 WHERE id=$4::uuid',[office['trial_end'],office['is_active'],office['plan'],office['id']])
