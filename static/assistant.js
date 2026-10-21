(() => {
    const stream = document.getElementById('zizo-chat-stream');
    if (!stream) return;
    const input = document.getElementById('zizo-input-text');
    const send = document.getElementById('btn-zizo-send');
    const caseSelect = document.getElementById('zizo-case-context');
    const status = document.getElementById('zizo-connection-status');
    let history = [], controller, busy = false, generation = 0, contextKey = '', storageKey = '', publicOnly = true;
    const engineNames = { guide: 'إرشاد المنظومة', constitution: 'نص الدستور الرسمي', openai: 'تحليل OpenAI', gemini: 'Gemini · سؤال عام', local_tools: 'أدوات محلية مجانية', setup_required: 'الخدمة تحتاج تفعيل' };
    const node = (tag, text, cls) => { const e = document.createElement(tag); if (text !== undefined) e.textContent = text; if (cls) e.className = cls; return e; };
    function safeURL(value) {
        try { const u = new URL(value, location.origin); return ['https:', 'http:'].includes(u.protocol) && !u.username ? u.href : null; } catch { return null; }
    }
    function inline(parent, text) {
        const pattern = /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)|\*\*([^*]+)\*\*/g;
        let match, at = 0;
        while ((match = pattern.exec(text))) {
            parent.append(document.createTextNode(text.slice(at, match.index)));
            if (match[3]) parent.append(node('strong', match[3]));
            else { const a = node('a', match[1]); const url = safeURL(match[2]); if (url) { a.href = url; a.target = '_blank'; a.rel = 'noopener noreferrer'; } parent.append(a); }
            at = pattern.lastIndex;
        }
        parent.append(document.createTextNode(text.slice(at)));
    }
    function renderText(parent, text) {
        text.replace(/cite[^]*/g, '').split('\n').forEach(line => {
            const heading = /^#{1,4}\s+/.test(line);
            const e = node(heading ? 'h4' : 'p'); inline(e, line.replace(/^#{1,4}\s+/, '')); parent.append(e);
        });
    }
    function action(parent, label, fn) { const b = node('button', label, 'zizo-action'); b.type = 'button'; b.addEventListener('click', fn); parent.append(b); }
    function append(role, text, data = {}) {
        const row = node('div', undefined, 'zizo-message ' + role);
        const bubble = node('div', undefined, 'zizo-bubble');
        if (role === 'user') bubble.textContent = text;
        else {
            bubble.append(node('div', engineNames[data.engine] || 'زيزو', 'zizo-message-label'));
            renderText(bubble, text);
            if (data.sources?.length) {
                const details = node('details', undefined, 'zizo-sources');
                details.append(node('summary', 'المصادر (' + data.sources.length + ')'));
                data.sources.forEach(source => { const url = safeURL(source.url); if (!url) return; const a = node('a', source.title || 'المصدر'); a.href = url; a.target = '_blank'; a.rel = 'noopener noreferrer'; details.append(a); });
                bubble.append(details);
            }
            if (typeof data.search_widget === 'string' && data.search_widget.length <= 30000) { const frame=node('iframe'); frame.title='اقتراحات بحث Google'; frame.setAttribute('sandbox','allow-popups allow-popups-to-escape-sandbox'); frame.srcdoc=data.search_widget; frame.className='zizo-search-widget'; bubble.append(frame); }
            const actions = node('div', undefined, 'zizo-message-actions');
            action(actions, 'نسخ الرد', async () => { try { await navigator.clipboard.writeText(text); showToast('تم نسخ الرد'); } catch { showToast('تعذر النسخ'); } });
            if (data.draft_memo) action(actions, 'فتح المسودة للمراجعة', () => applyMemoFromResponse(data.draft_memo));
            (data.actions || []).forEach(a => { if (['cases','sessions','home','more'].includes(a.view)) action(actions, a.label, () => switchView(a.view)); });
            bubble.append(actions);
        }
        row.append(bubble); stream.append(row); stream.scrollTop = stream.scrollHeight;
    }
    const privacy = node('label', undefined, 'zizo-public-label');
    const publicCheck = node('input'); publicCheck.type='checkbox'; publicCheck.id='zizo-public-query';
    privacy.append(publicCheck,document.createTextNode('سؤالي عام وخالٍ من البيانات الشخصية وأسرار القضايا'));
    const privacyNote=node('p','Gemini المجاني للأسئلة العامة فقط. لا تُرسل ملفات المكتب. استخدم الأدوات المحلية للبيانات الخاصة.','zizo-public-note');
    document.querySelector('.zizo-tools').append(privacy,privacyNote);
    const toolsLink=node('a','أدوات مجانية ↗'); toolsLink.href='/static/legal-tools.html'; toolsLink.target='_blank'; toolsLink.rel='noopener'; document.querySelector('.zizo-tools-row').append(toolsLink);
    function welcome() {
        stream.replaceChildren();
        append('assistant', 'أهلاً بيك. اسألني سؤالاً قانونياً عاماً بدون بيانات شخصية، أو اطلب نص مادة من الدستور بمصدرها.\nترتيب الوقائع ومقارنة النصوص وهيكل المذكرة متاحين مجاناً في الأدوات المحلية؛ ملفات المكتب لا تُرسل لـGemini المجاني.', { engine: 'guide', actions: [] });
        const chips = node('div', undefined, 'zizo-message-actions');
        ['تقدر تساعدني في إيه؟', 'نص المادة 54 من الدستور', 'الأدوات المجانية'].forEach(text => action(chips, text, () => { input.value = text; submit(); }));
        stream.append(chips);
    }
    function save() { try { if (storageKey) sessionStorage.setItem(storageKey, JSON.stringify(history.slice(-20))); } catch {} }
    async function refresh() {
        const token = (typeof currentOffice !== 'undefined' && currentOffice?.id) || getOfficeToken();
        const selected = caseSelect.value;
        try {
            const response = await apiFetch('/api/cases');
            if (response.ok) {
                const data = await response.json();
                caseSelect.replaceChildren(new Option('محادثة عامة — بدون ملف قضية', ''));
                (Array.isArray(data) ? data : []).forEach(c => caseSelect.add(new Option(`${c.number} · ${c.subject || ''}`, c.id)));
                caseSelect.value = [...caseSelect.options].some(o => o.value === selected) ? selected : '';
            }
        } catch { /* Keep general conversation usable while office data is offline. */ }
        if (contextKey !== token) {
            generation++; controller?.abort(); busy = false; send.disabled = false; caseSelect.disabled = publicOnly; history = []; contextKey = token;
            const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
            storageKey = 'zizo-v2-' + Array.from(new Uint8Array(digest)).map(b => b.toString(16).padStart(2, '0')).join('');
            try { const saved = JSON.parse(sessionStorage.getItem(storageKey) || '[]'); history = Array.isArray(saved) ? saved.filter(m => ['user','assistant'].includes(m.role) && typeof m.content === 'string' && m.content.length <= 16000).slice(-20) : []; } catch { history = []; }
            welcome(); history.forEach(m => append(m.role, m.content, m.response || { engine: 'guide' }));
        }
        try { const response = await apiFetch('/api/ai/status'); if (!response.ok) throw Error(); const data = await response.json(); publicOnly = data.public_questions_only !== false; privacy.hidden=!publicOnly; privacyNote.hidden=!publicOnly; caseSelect.disabled=publicOnly; if(publicOnly)caseSelect.value=''; input.placeholder=publicOnly?'سؤال قانوني عام بدون أسماء أو بيانات سرية…':'اكتب سؤالك…'; status.textContent = data.configured ? (publicOnly?'Gemini جاهز · أسئلة عامة':'جاهز للاتصال بالنموذج') : 'الأدوات المحلية جاهزة · مفتاح Gemini غير مفعّل'; } catch { status.textContent = 'تعذر فحص الاتصال'; }
    }
    function boundedHistory() {
        const messages = history.slice(-16).map(m => ({ role:m.role, content:m.content.slice(0,16000), public_query:m.public_query===true }));
        while (messages.reduce((sum,m)=>sum+m.content.length,0) > 50000) messages.shift();
        return messages;
    }
    async function submit(event, retryQuery) {
        event?.preventDefault();
        if (busy) return;
        const query = retryQuery || input.value.trim();
        if (!query) return;
        if (query.length > 12000) { showToast('الرسالة طويلة؛ قسّمها لأجزاء.'); return; }
        if (!retryQuery) append('user', query);
        input.value = ''; input.style.height = '';
        busy = true; send.disabled = true; caseSelect.disabled = true; input.setAttribute('aria-busy', 'true');
        const requestGeneration = generation;
        const loading = node('div', 'جارٍ فهم السؤال ومراجعة المعلومات', 'zizo-thinking'); stream.append(loading); stream.scrollTop = stream.scrollHeight;
        const stop = node('button', 'إيقاف الطلب', 'zizo-action'); stop.type = 'button'; loading.append(stop);
        controller = new AbortController(); let timedOut = false;
        stop.addEventListener('click', () => controller.abort());
        const timer = setTimeout(() => { timedOut = true; controller.abort(); }, 60000);
        try {
            const response = await apiFetch('/api/ai/zizo-advisor', { method: 'POST', signal: controller.signal, body: { query, history: boundedHistory(), case_id: caseSelect.value || null, mode: document.getElementById('zizo-mode').value, research: document.getElementById('zizo-research').checked, public_query:publicCheck.checked } });
            const data = await response.json().catch(() => ({}));
            if (!response.ok) { const detail = data.detail; throw Error(typeof detail === 'string' ? detail : detail?.message || (response.status === 404 ? 'مسار المحادثة غير متاح؛ أعد تحميل التطبيق.' : 'تعذر إكمال الطلب. حاول مجدداً.')); }
            if (requestGeneration !== generation) return;
            if (typeof data.advice !== 'string' || !data.advice.trim()) throw Error('وصل رد فارغ. أعد المحاولة.');
            append('assistant', data.advice, data);
            history.push({ role:'user',content:query,public_query:publicCheck.checked }, { role:'assistant',content:data.advice,public_query:publicCheck.checked,response:{engine:data.engine,sources:data.sources,search_widget:data.search_widget} }); history = history.slice(-20); save();
            status.textContent = ['openai','gemini'].includes(data.engine) ? (data.engine==='gemini'?'متصل بـGemini':'متصل بالنموذج') : (data.engine === 'setup_required' ? 'المكتبة متاحة · النموذج غير مفعّل' : status.textContent);
        } catch (error) {
            if (requestGeneration !== generation) return;
            const row = node('div', undefined, 'zizo-bubble zizo-error'); row.setAttribute('role', 'alert');
            const message = error.name === 'AbortError' ? (timedOut ? 'انتهت مهلة الاتصال. جرّب سؤالاً أقصر أو أعد المحاولة.' : 'تم إيقاف الطلب. لم يتم تغيير أي بيانات.') : error.message;
            row.append(node('p', message)); action(row, 'إعادة المحاولة', () => { row.remove(); submit(null, query); }); stream.append(row);
            status.textContent = 'الطلب لم يكتمل';
        } finally {
            clearTimeout(timer); loading.remove();
            if (requestGeneration === generation) { busy = false; send.disabled = false; caseSelect.disabled = publicOnly; input.removeAttribute('aria-busy'); stream.scrollTop = stream.scrollHeight; }
        }
    }
    function clear() {
        if (!confirm('بدء محادثة جديدة في التبويب الحالي؟ ملفات القضايا لن تتغير.')) return;
        generation++; controller?.abort(); history = []; save(); busy = false; send.disabled = false; caseSelect.disabled = publicOnly; input.removeAttribute('aria-busy'); welcome(); input.focus();
    }
    caseSelect.addEventListener('change', () => { if (history.length) { history = []; save(); welcome(); } });
    input.addEventListener('keydown', event => { if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') submit(event); });
    input.addEventListener('input', () => { input.style.height = 'auto'; input.style.height = Math.min(input.scrollHeight, 140) + 'px'; });
    window.ZizoAssistant = { submit, clear, refresh };
    welcome();
})();
