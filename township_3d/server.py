"""ToolVault 3D static server + OPTIONAL AI assistant endpoint.

Works with Python's standard library. Without OPENAI_API_KEY the game still has
working local recommendation rules in assistant.js. Never put a key in JS/Git.
"""
import json
import os
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
os.chdir(ROOT)
PORT = int(os.environ.get('TOOLVAULT_3D_PORT', '5500'))

TOOL_NAMES = [
    '4-step safety ladder', 'Cordless drill-driver kit', 'Wet & dry vacuum',
    'Carpet & upholstery cleaner', 'Adjustable pressure washer',
    'Household steam cleaner', 'Folding hand truck', 'Furniture moving kit',
    'Laser distance measurer', 'Self-leveling laser level',
    'Wall stud & wire detector', 'Folding workbench', 'Manual drain auger',
    'Portable dehumidifier', 'Ground-reach window cleaning kit',
]


class Handler(SimpleHTTPRequestHandler):
    def _json(self, code, payload):
        raw = json.dumps(payload).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(raw)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        if self.path == '/api/assistant/status':
            return self._json(200, {'live_ai': bool(os.environ.get('OPENAI_API_KEY'))})
        return super().do_GET()

    def do_POST(self):
        if self.path != '/api/assistant':
            return self._json(404, {'error': 'Unknown route'})
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size <= 4096:
                return self._json(400, {'error': 'Message too long or empty'})
            body = json.loads(self.rfile.read(size))
            question = body.get('question', '')
            if not isinstance(question, str) or not question.strip() or len(question) > 500:
                return self._json(400, {'error': 'Please provide a short question'})
        except (ValueError, TypeError, json.JSONDecodeError):
            return self._json(400, {'error': 'Invalid JSON'})
        key = os.environ.get('OPENAI_API_KEY', '').strip()
        if not key:
            return self._json(200, {'live_ai': False, 'answer': None})

        instructions = (
            'You are Tori, the helpful ToolVault township rental assistant. '
            'Use plain, concise English (max 100 words). Recommend only items '
            'in the real ToolVault catalogue: ' + ', '.join(TOOL_NAMES) + '. '
            'Explain what tool may suit the task and a concise safety note. '
            'Never claim a tool is currently available, or that a reservation was created; '
            'the resident must verify stock and book using the actual Flutter app. '
            'If a situation seems dangerous (live electrical, gas, fire, structural, severe flooding), '
            'recommend qualified professionals instead of a tool. '
            'For navigation questions say: WASD to walk, E anywhere outside locker for phone booking, '
            'E at the locker to collect or return, Esc closes the panel.'
        )
        data = json.dumps({
            'model': os.environ.get('OPENAI_MODEL', 'gpt-4.1-mini'),
            'instructions': instructions,
            'input': question,
            'max_output_tokens': 220,
            'store': False,
        }).encode('utf-8')
        request = urllib.request.Request(
            'https://api.openai.com/v1/responses', data=data,
            headers={'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'},
            method='POST'
        )
        try:
            with urllib.request.urlopen(request, timeout=22) as resp:
                doc = json.loads(resp.read(100000))
            # Responses API returns generated text in output[].content[].text.
            text = ' '.join(piece.get('text', '')
                            for item in doc.get('output', [])
                            for piece in item.get('content', [])
                            if piece.get('type') == 'output_text').strip()
            return self._json(200, {'live_ai': bool(text), 'answer': text or None})
        except (urllib.error.URLError, TimeoutError, ValueError, OSError) as exc:
            print('Optional live AI unavailable:', type(exc).__name__)
            return self._json(200, {'live_ai': False, 'answer': None})


if __name__ == '__main__':
    print(f'\nTOOLVAULT 3D: http://localhost:{PORT}\n')
    print('Resident Flutter: http://localhost:5000')
    print('Locker Flutter:   http://localhost:5001')
    print('AI mode:', 'optional live API enabled' if os.environ.get('OPENAI_API_KEY') else 'built-in recommendations (no API key)')
    ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
