const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');

const app = express();
const port = 3000;
const db = new sqlite3.Database('./database.sqlite');
// Middleware
app.use(bodyParser.json());

// データベースの初期化
db.serialize(() => {
    db.run(`
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT
        )
    `);
    db.run(`
        CREATE TABLE posts (
            id INTEGER PRIMARY KEY,
            userId INTEGER,
            comment TEXT,
            FOREIGN KEY(userId) REFERENCES users(id)
        )
    `);
    db.run(`
        CREATE TABLE bookmarks (
            userId INTEGER,
            postId INTEGER,
            PRIMARY KEY(userId, postId),
            FOREIGN KEY(userId) REFERENCES users(id),
            FOREIGN KEY(postId) REFERENCES posts(id)
        )
    `);

    // サンプルデータの挿入
    db.run(`INSERT INTO users (name) VALUES ('Alice')`);
    db.run(`INSERT INTO users (name) VALUES ('Bob')`);
    for (let i = 0; i < 100; i++) {
        db.run(`INSERT INTO posts (userId, comment) VALUES (1, 'Post ${i + 1}')`);
    }
});

// 記事のフィード取得
app.get('/posts', (req, res) => {
    const userId = req.header('user-id'); // ヘッダーからログインIDを取得
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    db.all(`
        SELECT 
            posts.id, 
            users.name, 
            posts.comment,
            CASE WHEN bookmarks.userId IS NOT NULL THEN 1 ELSE 0 END AS isBookmarked
        FROM posts 
        JOIN users ON posts.userId = users.id
        LEFT JOIN bookmarks ON posts.id = bookmarks.postId AND bookmarks.userId = ?
        LIMIT ? OFFSET ?
    `, [userId, limit, offset], (err, rows) => {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }

        // isBookmarkedをbooleanに変換
        const posts = rows.map(row => ({
            ...row,
            isBookmarked: row.isBookmarked === 1
        }));

        res.json({posts});
    });
});

// プロフィール画面用の情報取得
app.get('/profile/:userId', (req, res) => {
    const userId = req.params.userId;
    db.get(`SELECT * FROM users WHERE id = ?`, [userId], (err, row) => {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }
        res.json({profile: row});
    });
});

// 記事の詳細取得
app.get('/posts/:postId', (req, res) => {
    const postId = req.params.postId;
    const userId = req.header('user-id'); // ヘッダーからログインIDを取得
    db.get(`
        SELECT 
            posts.id, 
            users.name, 
            posts.comment,
            CASE WHEN bookmarks.userId IS NOT NULL THEN 1 ELSE 0 END AS isBookmarked
        FROM posts 
        JOIN users ON posts.userId = users.id
        LEFT JOIN bookmarks ON posts.id = bookmarks.postId AND bookmarks.userId = ?
        WHERE posts.id = ?
    `, [userId, postId], (err, row) => {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }

        // isBookmarkedをbooleanに変換
        const post = {
            ...row,
            isBookmarked: row.isBookmarked === 1
        };

        res.json({post});
    });
});

// ブックマーク追加
app.post('/bookmarks', (req, res) => {
    const { userId, postId } = req.body;
    db.run(`INSERT INTO bookmarks (userId, postId) VALUES (?, ?)`, [userId, postId], function(err) {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }
        res.json({message: 'Bookmark added'});
    });
});

// ブックマーク削除
app.delete('/bookmarks', (req, res) => {
    const { userId, postId } = req.body;
    db.run(`DELETE FROM bookmarks WHERE userId = ? AND postId = ?`, [userId, postId], function(err) {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }
        res.json({message: 'Bookmark removed'});
    });
});

// 特定ユーザーのブックマークリスト取得
app.get('/bookmarks/:userId', (req, res) => {
    const userId = req.params.userId;
    db.all(`
        SELECT 
            posts.id, 
            users.name, 
            posts.comment, 
            CASE WHEN bookmarks.userId IS NOT NULL THEN 1 ELSE 0 END AS isBookmarked
        FROM bookmarks 
        JOIN posts ON bookmarks.postId = posts.id 
        JOIN users ON posts.userId = users.id 
        WHERE bookmarks.userId = ?
    `, [userId], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }

        // isBookmarkedをbooleanに変換
        const bookmarks = rows.map(row => ({
            ...row,
            isBookmarked: row.isBookmarked === 1
        }));

        res.json({ bookmarks });
    });
});

// 特定ユーザーの投稿リスト取得
app.get('/posts/user/:userId', (req, res) => {
    const userId = req.params.userId;
    db.all(`SELECT id, comment FROM posts WHERE userId = ?`, [userId], (err, rows) => {
        if (err) {
            res.status(500).json({error: err.message});
            return;
        }
        res.json({posts: rows});
    });
});

// 記事削除
app.delete('/posts/:postId', (req, res) => {
    const postId = req.params.postId;
    db.run(`DELETE FROM posts WHERE id = ?`, [postId], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ message: 'Post deleted' });
    });
});

// サーバー起動
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
});