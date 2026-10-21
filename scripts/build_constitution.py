"""Extract the official Parliament/Presidency 2019 constitution PDF (pypdf, build-time only)."""
import hashlib
import json
import re
from pathlib import Path
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / 'static/knowledge/egypt-constitution-2019.pdf'
SOURCE = 'https://www.presidency.eg/media/46122/دستور-جمهورية-مصر-العربية-2019.pdf'


def logical_digits(text):
    # This PDF encodes Arabic-Indic numbers in visual order; ASCII runs are logical.
    return re.sub(r'[٠-٩]+', lambda m: m[0][::-1].translate(str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')), text)


def build():
    reader = PdfReader(PDF)
    articles, preamble, current = [], [], None
    preamble_started = False
    heading = re.compile(r'^مادة\s*[()]?\s*(\d+)\s*(مكررا[ًا]?|مكرر)?')
    for page_number, page in enumerate(reader.pages, 1):
        lines = [logical_digits(line).strip() for line in page.extract_text().splitlines()]
        # Skip repeated running page headers, but retain the complete body/preamble.
        markers = [i for i, line in enumerate(lines) if re.fullmatch(r'-\s*\d+\s*-', line)]
        if markers:
            lines = lines[markers[0] + 1:]
        in_notes, in_section = False, False
        for line in lines:
            if not line or re.fullmatch(r'[ـ_\-\s]+', line):
                continue
            if line.startswith('بسم الله الرحمن الرحيم'):
                preamble_started = True
            if line == 'الفهرس':
                in_section = True
            if re.match(r'^[()]\s*\d+\s*[()]\s', line):
                in_notes = True
            if in_notes:
                if current:
                    current['notes'].append(line)
                continue
            match = heading.match(line)
            if match:
                number = int(match[1])
                # The PDF font emits article 238 as 382; verified against page 106.
                if number == 382 and current and current['number'] == 237:
                    number = 238
                suffix = ' مكرر' if match[2] else ''
                current = {'id': f'{number}{suffix}', 'number': number, 'label': f'المادة {number}{suffix}', 'page': page_number, 'paragraphs': [], 'notes': []}
                articles.append(current)
                in_section = False
                continue
            if re.match(r'^(الباب|الفصل|الفرع)\s', line):
                in_section = True
            if in_section:
                continue
            if current:
                current['paragraphs'].append(line)
            elif preamble_started:
                preamble.append(line)
    for article in articles:
        article['text'] = re.sub(r'\s+', ' ', ' '.join(article.pop('paragraphs'))).strip()
        article['notes'] = re.sub(r'\s+', ' ', ' '.join(article['notes'])).strip()
        article['source_url'] = SOURCE + '#page=' + str(article['page'])
    ids = [a['id'] for a in articles]
    assert len(ids) == len(set(ids)), 'Duplicate article identifiers'
    missing = sorted(set(range(1, 255)) - {a['number'] for a in articles})
    assert not missing, f'Missing articles: {missing}'
    assert all(a['text'] for a in articles), 'Empty article'
    assert len(reader.pages) == 114
    data = {'title': 'دستور جمهورية مصر العربية 2014 المعدل في أبريل 2019', 'edition': '2019-04', 'retrieved_on': '2026-10-21', 'source_url': SOURCE, 'source_publisher': 'رئاسة الجمهورية المصرية / مجلس النواب', 'source_sha256': hashlib.sha256(PDF.read_bytes()).hexdigest(), 'pdf_pages': 114, 'extraction_note': 'النص مستخرج آلياً من النسخة الرسمية؛ راجع صورة الصفحة الأصلية عند الاقتباس الحرفي. لا تُدمج حواشي التعديل في النص النافذ.', 'preamble': '\n'.join(preamble), 'articles': articles}
    dest = ROOT / 'static/knowledge/egypt-constitution-2019.json'
    dest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print({'articles': len(articles), 'bytes': dest.stat().st_size, 'preamble_characters': len(data['preamble']), 'missing': missing})
    for number in [10, 54, 102, 140, 150, 185, 198, 241, 254]:
        for a in articles:
            if a['number'] == number:
                print(a['label'], 'page', a['page'], a['text'][:180])

if __name__ == '__main__':
    build()
