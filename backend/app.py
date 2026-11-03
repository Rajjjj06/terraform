import json

from flask import Flask, jsonify, request
from pathlib import Path


app = Flask(__name__)
data_file = Path(__file__).with_name('data.json')


@app.get('/health')
def health():
    return jsonify({'status': 'ok'})


@app.post('/submit')
def submit():
    data = request.get_json(silent=True) or {}
    name = str(data.get('name', '')).strip()
    age = str(data.get('age', '')).strip()
    city = str(data.get('city', '')).strip()

    if not name or not age or not city:
        return jsonify({'error': 'name, age, and city are required'}), 400

    submissions = []
    if data_file.exists():
        with data_file.open('r', encoding='utf-8') as f:
            submissions = json.load(f)

    submissions.append({
        'name': name,
        'age': age,
        'city': city,
    })

    with data_file.open('w', encoding='utf-8') as f:
        json.dump(submissions, f, indent=2)

    return jsonify({'status': 'processed'}), 201


@app.get('/data')
def get_data():
    if not data_file.exists():
        return jsonify({'error': 'no submitted data'}), 404

    with data_file.open('r', encoding='utf-8') as f:
        return jsonify(json.load(f))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)