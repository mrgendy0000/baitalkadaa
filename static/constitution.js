(async () => {
    const list = document.getElementById('constitution-articles');
    const input = document.getElementById('constitution-search');
    const count = document.getElementById('constitution-count');
    const more = document.getElementById('constitution-more');
    const normal = text => text.normalize('NFKC').replace(/[أإآ]/g,'ا').replace(/ى/g,'ي').replace(/ة/g,'ه').replace(/[\u064b-\u065fـ]/g,'').replace(/[٠-٩]/g,d=>'٠١٢٣٤٥٦٧٨٩'.indexOf(d));
    let articles = [], matches = [], shown = 0;
    function render() {
        matches.slice(shown, shown + 20).forEach(a => {
            const card = document.createElement('article'); card.className = 'article'; card.id = 'article-' + a.id;
            const h = document.createElement('h2'); h.textContent = a.label;
            const p = document.createElement('p'); p.textContent = a.text;
            const link = document.createElement('a'); link.textContent = 'المصدر الرسمي — صفحة ' + a.page; link.href = a.source_url; link.target = '_blank'; link.rel = 'noopener noreferrer';
            card.append(h,p,link);
            if (a.notes) { const d = document.createElement('details'); const s = document.createElement('summary'); s.textContent = 'حاشية التعديل في النسخة الرسمية'; const t = document.createElement('p'); t.textContent = a.notes; d.append(s,t); card.append(d); }
            list.append(card);
        });
        shown = Math.min(shown + 20, matches.length); more.hidden = shown >= matches.length;
        count.textContent = `${matches.length} مادة مطابقة من ${articles.length} · المعروض ${shown}`;
    }
    function search() {
        const q = normal(input.value.trim());
        matches = articles.filter(a => !q || (/^\d+$/.test(q) ? String(a.number) === q : normal(a.label + ' ' + a.text).includes(q)));
        shown = 0; list.replaceChildren(); render();
    }
    try {
        const response = await fetch('/static/knowledge/egypt-constitution-2019.json'); if (!response.ok) throw Error(); const data = await response.json();
        articles = data.articles; document.getElementById('constitution-preamble').textContent = data.preamble;
        document.getElementById('official-source').href = data.source_url;
        input.addEventListener('input', search); more.addEventListener('click', render); search();
    } catch { count.textContent = 'تعذر تحميل المكتبة. أعد تحميل الصفحة.'; }
})();
