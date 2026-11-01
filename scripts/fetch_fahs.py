import urllib.request
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
TOKEN = 'ntn_b338236176350RyZfcfGSEIDlKl6YnNYB0R46Rla7hzao4'
PAGE_ID = '40a0c99a-bea3-8172-a53f-f4fc505a8053'

def get_text(rich_texts):
    if not rich_texts:
        return ''
    return ''.join(t.get('plain_text', '') for t in rich_texts)

def fetch_blocks(block_id):
    blocks = []
    cursor = None
    while True:
        url = f'https://api.notion.com/v1/blocks/{block_id}/children?page_size=100'
        if cursor:
            url += f'&start_cursor={cursor}'
        req = urllib.request.Request(url, headers={
            'Authorization': f'Bearer {TOKEN}',
            'Notion-Version': '2022-06-28'
        })
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            blocks.extend(data.get('results', []))
            if not data.get('has_more'):
                break
            cursor = data.get('next_cursor')
    return blocks

def render_block(b, indent=0):
    btype = b.get('type')
    content = b.get(btype, {})
    pad = '  ' * indent
    lines = []
    
    if btype == 'heading_1':
        lines.append(f'\n# {get_text(content.get("rich_text", []))}\n')
    elif btype == 'heading_2':
        lines.append(f'\n## {get_text(content.get("rich_text", []))}\n')
    elif btype == 'heading_3':
        lines.append(f'\n### {get_text(content.get("rich_text", []))}\n')
    elif btype == 'paragraph':
        t = get_text(content.get('rich_text', []))
        if t:
            lines.append(f'{pad}{t}\n')
    elif btype == 'bulleted_list_item':
        lines.append(f'{pad}* {get_text(content.get("rich_text", []))}')
    elif btype == 'numbered_list_item':
        lines.append(f'{pad}1. {get_text(content.get("rich_text", []))}')
    elif btype == 'to_do':
        chk = 'x' if content.get('checked') else ' '
        lines.append(f'{pad}- [{chk}] {get_text(content.get("rich_text", []))}')
    elif btype == 'toggle':
        lines.append(f'{pad}> **{get_text(content.get("rich_text", []))}**')
    elif btype == 'quote':
        lines.append(f'{pad}> {get_text(content.get("rich_text", []))}')
    elif btype == 'callout':
        lines.append(f'{pad}> [!NOTE]\n{pad}> {get_text(content.get("rich_text", []))}')
    elif btype == 'code':
        lang = content.get('language', '')
        t = get_text(content.get('rich_text', []))
        lines.append(f'{pad}```{lang}\n{t}\n{pad}```')
    elif btype == 'divider':
        lines.append('\n---\n')
    else:
        t = get_text(content.get('rich_text', [])) if isinstance(content, dict) and 'rich_text' in content else ''
        if t:
            lines.append(f'{pad}{t}')

    if b.get('has_children'):
        children = fetch_blocks(b['id'])
        for child in children:
            lines.extend(render_block(child, indent + 1))
            
    return lines

all_blocks = fetch_blocks(PAGE_ID)
rendered = ['# فحص\n']
for b in all_blocks:
    rendered.extend(render_block(b))

out_path = r'E:\al-umrabischool\docs\notion_sync\notion_fahs.md'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(rendered))

print(f'Successfully saved {len(rendered)} lines to {out_path}')
