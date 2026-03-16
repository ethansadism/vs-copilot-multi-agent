from flask import Flask, jsonify, render_template
import database

app = Flask(__name__)

# Initialize database on startup if not exists
database.init_db()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/data')
def get_data():
    posts = database.get_posts()
    return jsonify(posts)

if __name__ == '__main__':
    app.run(debug=True, port=8989)
