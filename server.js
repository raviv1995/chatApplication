var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);
const { Client } = require('pg');

const client = new Client({
    user: 'postgres',
    host: '127.0.0.1',
    database: 'chatdb',
    password: '123',
    port: 9876,
});

client.connect();
client.query('SELECT * FROM chat_schema.users', (err, res) => {
  console.log(err ? err.stack : res.rows[0].message) 
  client.end()
});


app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

users = [];
io.on('connection', function(socket) {
    // Client connection event
    console.log('A user connected');
    socket.on('setUsername', function(data) {
        console.log(data);
        console.log(socket);
        if(users.indexOf(data) > -1) {
            socket.emit('userExists', data + ' username is taken! Try some other username.');
        } else {
            users.push(data);
            socket.emit('userSet', {username: data});
        }
    });
    
    socket.on('msg', function(data) {
        // Send message to everyone
        io.sockets.emit('newmsg', data);
    })

    socket.on('disconnect', () => {
        // Disconnection of client
        console.log("Client disconnected");
    });
      
});

http.listen(3000, () => {
    console.log('listening on *:3000');
});