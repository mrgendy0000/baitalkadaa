-- ==============================================================================
-- قاعدة بيانات المساعد القانوني الذكي المصري (Egyptian Legal AI Platform Schema)
-- متوافقة مع PostgreSQL 15+ مع تفعيل ملحق pgvector للبحث الدلالي والمتجهي
-- ==============================================================================

-- تفعيل الملحقات الضرورية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- -----------------------------------------------------------------------------
-- 1. جدول التقنينات ومجموعات القوانين المصرية (Law Codes / Statutes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS law_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code_name VARCHAR(255) NOT NULL UNIQUE,       -- مثال: قانون العقوبات، قانون الإجراءات الجنائية، الدستور
    official_number VARCHAR(100),                  -- مثال: القانون رقم 58 لسنة 1937
    issuance_year INTEGER,                         -- سنة الإصدار
    category VARCHAR(100) NOT NULL,               -- جنائي، مدني، مرافعات، دستوري، أسرة، إداري، عمل
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. جدول مواد الدستور والقوانين والتضمينات المتجهية (Law Articles & Embeddings)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS law_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    law_code_id UUID REFERENCES law_codes(id) ON DELETE CASCADE,
    law_name VARCHAR(255) NOT NULL,                -- اسم القانون لسهولة الاستعلام السريع
    article_number VARCHAR(50) NOT NULL,           -- رقم المادة (مثال: مادة 54، مادة 341، مادة 18 مكرر)
    article_title VARCHAR(255),                    -- عنوان المادة أو الباب
    article_content TEXT NOT NULL,                 -- نص المادة الكامل
    legislative_notes TEXT,                        -- المذكرات الإيضاحية والتعديلات
    branch VARCHAR(100) NOT NULL,                  -- فرع القانون
    keywords TEXT[],                               -- الكلمات المفتاحية
    embedding vector(1536),                        -- التضمين المتجهي للنص للبحث الدلالي
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- فهارس البحث المتجهي والبحث النصي الكامل
CREATE INDEX IF NOT EXISTS idx_law_articles_embedding 
ON law_articles USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_law_articles_fts 
ON law_articles USING gin (to_tsvector('simple', article_content));

CREATE INDEX IF NOT EXISTS idx_law_articles_law_num 
ON law_articles (law_name, article_number);

-- -----------------------------------------------------------------------------
-- 3. جدول أحكام ومبادئ محكمة النقض المصرية (Egyptian Cassation Rulings)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cassation_rulings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appeal_number VARCHAR(50) NOT NULL,            -- رقم الطعن (مثال: 14258)
    judicial_year VARCHAR(50) NOT NULL,            -- السنة القضائية (مثال: 86 ق)
    circuit VARCHAR(100) NOT NULL,                 -- الدائرة: الدائرة الجنائية، الدائرة المدنية، دائرة الإيجارات
    ruling_date DATE,                              -- تاريخ جلسة الحكم
    legal_topic VARCHAR(255) NOT NULL,             -- موضوع المبدأ (بطلان القبض، ركن التسليم في خيانة الأمانة)
    legal_principle TEXT NOT NULL,                 -- المبدأ القانوني المستخلص المنشور بالمكتب الفني
    full_text TEXT,                                -- حيثيات الحكم ومنطوقه كاملاً
    source_ref VARCHAR(255),                       -- رقم الجزء والصفحة بمجموعة المكتب الفني
    embedding vector(1536),                        -- التضمين المتجهي للمبدأ القانوني
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- فهارس أحكام النقض
CREATE INDEX IF NOT EXISTS idx_cassation_embedding 
ON cassation_rulings USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_cassation_fts 
ON cassation_rulings USING gin (to_tsvector('simple', legal_principle || ' ' || legal_topic));

CREATE INDEX IF NOT EXISTS idx_cassation_appeal 
ON cassation_rulings (appeal_number, judicial_year);

-- -----------------------------------------------------------------------------
-- 4. جدول الموكلين (Clients)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    national_id VARCHAR(14) UNIQUE,                -- الرقم القومي (14 رقم)
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    power_of_attorney_num VARCHAR(100),            -- رقم التوكيل الرسمي العام (مثال: 1425 لسنة 2024 توثيق الأهرام)
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 5. جدول القضايا (Cases)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number VARCHAR(100) NOT NULL,             -- رقم القضية أو المحضر (مثال: 1258 لسنة 2024 جنح المعادي)
    case_year INTEGER NOT NULL,                    -- سنة القضية
    case_type VARCHAR(100) NOT NULL,               -- جناية، جنحة، استئناف مدني، أسرة، تعويضات، نقض
    court_name VARCHAR(255) NOT NULL,              -- المحكمة المختصة (مثال: محكمة جنوب القاهرة الابتدائية)
    circuit VARCHAR(100),                          -- اسم الدائرة
    client_id UUID REFERENCES clients(id) ON DELETE RESTRICT,
    client_capacity VARCHAR(100) NOT NULL,         -- صفة الموكل: مدعي، مدعى عليه، مجني عليه، متهم، مستأنف
    opposing_party VARCHAR(255) NOT NULL,          -- الخصم
    opposing_lawyer VARCHAR(255),                  -- محامي الخصم
    status VARCHAR(50) DEFAULT 'ACTIVE',           -- ACTIVE, WON, CLOSED, APPEALED, SUSPENDED
    dispute_subject TEXT NOT NULL,                 -- موضوع النزاع والوقائع
    judgment_summary TEXT,                         -- ملخص الحكم الصادر إن وجد
    judgment_date DATE,                            -- تاريخ النطق بالحكم
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cases_client_id ON cases (client_id);
CREATE INDEX IF NOT EXISTS idx_cases_number_year ON cases (case_number, case_year);

-- -----------------------------------------------------------------------------
-- 6. جدول جلسات رول المحكمة (Court Sessions & Roll Tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS court_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,                    -- تاريخ الجلسة
    roll_number INTEGER,                           -- رقم الرول في الجلسة
    last_decision TEXT,                            -- قرار الجلسة السابقة
    session_status VARCHAR(50) DEFAULT 'SCHEDULED',-- SCHEDULED, ATTENDED, POSTPONED, DECIDED
    required_action TEXT,                          -- المطلوب للجلسة (مذكرة دفاع، سداد رسم، إعلان، خبير)
    judge_ruling TEXT,                             -- المنطوق أو القرار الصادر في الجلسة الحالية
    adjournment_date DATE,                         -- تاريخ التأجيل للجلسة القادمة
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_court_sessions_date ON court_sessions (session_date);
CREATE INDEX IF NOT EXISTS idx_court_sessions_case ON court_sessions (case_id);

-- -----------------------------------------------------------------------------
-- 7. جدول جلسات محادثات المساعد القانوني (Chat Sessions / Rooms)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL DEFAULT 'استشارة قانونية جديدة',
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    system_role VARCHAR(100) DEFAULT 'EGYPTIAN_LEGAL_ADVISOR',
    metadata JSONB DEFAULT '{}'::jsonb,            -- معلومات إضافية عن نوع الاستشارة والدعوى
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 8. جدول رسائل المحادثات والمراجع والمذكرات (Chat Messages & Legal Citations)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,                     -- user, assistant, system
    content TEXT NOT NULL,                         -- نص السؤال أو الاستشارة
    citations JSONB DEFAULT '[]'::jsonb,           -- مراجع المواد وأحكام النقض المستند إليها
    draft_memo JSONB DEFAULT NULL,                 -- مسودة المذكرة القضائية المولدة المتضمنة الدفوع والطلبات
    tokens_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages (session_id);

-- -----------------------------------------------------------------------------
-- 9. بيانات تأسيسية أولية لمواد القوانين المصرية وأحكام النقض الجوهرية (Seed Data)
-- -----------------------------------------------------------------------------

-- إدخال التقنينات
INSERT INTO law_codes (code_name, official_number, issuance_year, category, description)
VALUES 
('الدستور المصري', 'دستور 2014 المعدل 2019', 2014, 'دستوري', 'أسمى القوانين الحامية للحريات العامة وحق التقاضي والضمانات الجنائية'),
('قانون العقوبات المصري', 'القانون رقم 58 لسنة 1937', 1937, 'جنائي', 'الجرائم والعقوبات المقررة لكل منها وموانع المسؤولية الجنائية'),
('قانون الإجراءات الجنائية', 'القانون رقم 150 لسنة 1950', 1950, 'إجراءات جنائية', 'تنظيم حالات التلبس، القبض، التفتيش، الطعون والاستئناف الجنائي'),
('قانون المرافعات المدنية والتجارية', 'القانون رقم 13 لسنة 1968', 1968, 'مرافعات', 'مواعيد الطعون، وإجراءات رفع الدعاوى وإعلانات المحضرين والمحاكم'),
('القانون المدني المصري', 'القانون رقم 131 لسنة 1948', 1948, 'مدني', 'الالتزامات والعقود والحقوق العينية والشخصية والمسؤولية التقصيرية')
ON CONFLICT (code_name) DO NOTHING;

-- إدخال مواد مختارة ذات أهمية بالغة
INSERT INTO law_articles (law_name, article_number, article_title, article_content, branch, keywords)
VALUES
(
    'الدستور المصري',
    'المادة 54',
    'حرمة الحرية الشخصية وحظر القبض التعسفي',
    'الحرية الشخصية حق طبيعي، وهي مصونة لا تُمس، وفيما عدا حالة التلبس، لا يجوز القبض على أحد، أو تفتيشه، أو حبسه، أو تقييد حريته بأي قيد إلا بأمر قضائي مسبب يستلزمه التحقيق. ويجب أن يُبلغ فوراً كل من تقيد حريته بأسباب ذلك، ويحاط بحقوقه كتابة، ويُمكّن من الاتصال بذويه وبمحاميه فوراً، وأن يُقدم إلى سلطة التحقيق خلال أربع وعشرين ساعة من وقت تقييد حريته.',
    'دستوري',
    ARRAY['الحرية الشخصية', 'القبض', 'التفتيش', 'بطلان', 'التحقيق', 'التلبس']
),
(
    'قانون الإجراءات الجنائية',
    'المادة 30',
    'حالات التلبس بالجريمة على سبيل الحصر',
    'تكون الجريمة متلبساً بها حال ارتكابها أو عقب ارتكابها ببرهة يسيرة. وتعتبر الجريمة متلبساً بها إذا تبع المجني عليه مرتكبها أو تبعته العامة مع الصياح إثر وقوعها، أو إذا وجد مرتكبها بعد وقوعها بوقت قريب حاملاً آلات أو أسلحة أو أمتعة أو أوراقاً أو أشياء أخرى يستدل منها على أنه فاعل أو شريك فيها، أو إذا وجدت به في هذا الوقت آثار أو علامات تفيد ذلك.',
    'جنائي',
    ARRAY['التلبس', 'بطلان القبض', 'الإجراءات الجنائية', 'المشاهدة الحية']
),
(
    'قانون العقوبات المصري',
    'المادة 341',
    'جريمة خيانة الأمانة وعقود الأمانة الخمسة',
    'كل من اختلس أو استعمل أو بدد مبالغ أو أمتعة أو بضائع أو نقوداً أو تذاكر أو كتابات أخرى مشتملة على تمسك أو مخالصة أو غير ذلك إضراراً بمالكيها أو أصحابها أو واضعي اليد عليها وكانت الأشياء المذكورة لم تسلم له إلا على وجه الوديعة أو الإجارة أو على سبيل عارية الاستعمال أو الرهن أو كانت سلمت له بصفته وكيلاً بأجرة أو مجاناً بقصد عرضها للبيع أو بيعها أو استعمالها في أمر معين لمنفعة المالك لها أو غيره يحكم عليه بالحبس ويجوز أن يزاد عليه غرامة لا تتجاوز مائة جنيه مصري.',
    'جنائي',
    ARRAY['خيانة أمانة', 'إيصال أمانة', 'عقد الوديعة', 'ركن التسليم', 'قصد جنائي']
),
(
    'قانون المرافعات المدنية والتجارية',
    'المادة 18',
    'امتداد المواعيد القانونية عند مصادفة عطلة رسمية',
    'إذا صادف آخر الميعاد عطلة رسمية امتد إلى أول يوم عمل بعدها. وتعتبر أيام الجمع والسبت والأعياد الرسمية المقررة بقوانين أو قرارات من مجلس الوزراء عطلات رسمية يمتد الميعاد بانتهائها.',
    'مرافعات',
    ARRAY['المواعيد الإجرائية', 'العطلات القضائية', 'امتداد الميعاد', 'سقوط الحق']
),
(
    'قانون المرافعات المدنية والتجارية',
    'المادة 227',
    'ميعاد الاستئناف في المواد المدنية والمستعجلة',
    'ميعاد الاستئناف أربعون يوماً ما لم ينص القانون على غير ذلك، ويكون الميعاد خمسة عشر يوماً في المسائل المستعجلة أياً كانت المحكمة التي أصدرت الحكم. ويسري الميعاد من تاريخ صدور الحكم إذا كان حضورياً أو من تاريخ إعلانه قانوناً إن كان غيابياً.',
    'مرافعات',
    ARRAY['استئناف مدني', 'مستعجل', '40 يوما', '15 يوما', 'ميعاد الطعن']
);

-- إدخال مبادئ محكمة النقض المصرية التأسيسية
INSERT INTO cassation_rulings (appeal_number, judicial_year, circuit, ruling_date, legal_topic, legal_principle, full_text, source_ref)
VALUES
(
    '15421',
    '84 ق',
    'الدائرة الجنائية',
    '2015-04-12',
    'بطلان القبض والتفتيش لانتفاء حالة التلبس',
    'حالة التلبس تستوجب أن يشهد مأمور الضبط القضائي الجريمة بنفسه بإحدى حواسه؛ فلا يغني عن ذلك تلقي نبأها عن طريق الرواية أو الإخبار ما لم يشهد أثراً ظاهراً ينبئ بذاته عن وقوعها. وحيث إن الثابت أن الضابط لم يشاهد الجريمة فإن قيامه بالقبض والتفتيش يقع باطلاً ويبطل كل دليل مستمد منه عملاً بقاعدة ما بني على باطل فهو باطل.',
    'حكم محكمة النقض الصادر بجلسة 12 أبريل 2015 برئاسة المستشار نائب رئيس المحكمة وعضوية السادة المستشارين...',
    'مجموعة أحكام النقض الجنائية - س 66 ص 412'
),
(
    '982',
    '72 ق',
    'الدائرة الجنائية',
    '2003-11-18',
    'انتفاء ركن التسليم الحقيقي في إيصال الأمانة واستعماله كأداة ضمان',
    'من المقرر أن جريمة خيانة الأمانة لا تقوم إلا إذا كان تسليم المال قد تم حقيقة على سبيل الأمانة بمقتضى أحد عقود الأمانة المبينة حصراً بالمادة 341 من قانون العقوبات. فإذا ثبت أن الورقة (إيصال الأمانة) قد حُررت لضمان معاملة مدنية أو كضمان تجاري ولم يكن هناك تسليم فعلي للمال نقداً فإن الواقعة تنحسر عنها الحماية الجنائية وتكون بمنأى عن التأثيم الجنائي ويتعين القضاء بالبراءة.',
    'حكم محكمة النقض الدائرة الجنائية في الطعن رقم 982 لسنة 72 قضائية جلسة 18/11/2003...',
    'مجموعة المكتب الفني - س 54 ص 890'
),
(
    '4410',
    '65 ق',
    'الدائرة المدنية',
    '1996-02-28',
    'حساب مواعيد الطعن بالاستئناف وامتداد الميعاد بالعطلة الرسمية',
    'ميعاد الطعن بالاستئناف في الأحكام المدنية يكتمل بانقضاء اليوم الأخير منه، وإذا صادف هذا اليوم الأخير عطلة رسمية فإن الميعاد يمتد عملاً بالمادة 18 من قانون المرافعات إلى أول يوم عمل رسمي يلي العطلة. ولا تسقط الدعوى أو يقضى بعدم قبول الاستئناف شكلاً إلا إذا انقضى اليوم الأول من أيام العمل التالية للعطلة دون إيداع صحيفة الاستئناف قلم الكتاب.',
    'الطعن بالنقض المدني المقيد برقم 4410 لسنة 65 ق جلسة 28 فبراير 1996...',
    'مجموعة أحكام النقض المدنية - س 47 ص 285'
);
