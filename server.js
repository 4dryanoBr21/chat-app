// declarando variaveis para usar o express e o socket.io de forma facilitada
const express = require('express');
const path = require('path');

const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server);

// definindo onde o express vai procurar os arquivos .html .css entre outros
app.use(express.static(path.join(__dirname, 'public'))); // localizando diretório public na raiz do sistema
app.set('views', path.join(__dirname, 'public')); // direcionando as viwes para a pasta public
app.engine('html', require('ejs').renderFile); // alterando a forma de renderização para reconhecer arquivos .html pois o padrão é .ejs
app.set('view engine', 'html')

// rota padrão renderizando o index.html
app.use('/', (req, res) => {
    res.render('index.html')
});

// lista de mensagens do chat em um array. Obs: Não tem banco de dados para as mensagens e usuários por estava com prequisa :)
let messages = []

// socket.io e tratamento dos dados
io.on('connection', socket => {
    console.log(`Socket conectado: ${socket.id}`); // básico comando para saber se o socker.io está funcionando na pagina

    socket.emit('previousMessages', messages); // mostrando as mensagens do array mesmo se atualziar a pagina 

    socket.on('sendMessage', data => {
        messages.push(data); // puxando as mesnagens para o atributo data
        socket.broadcast.emit('newMessage', data); // mostrando novas mensagens na tela
    })
});

server.listen(3000); // porta do servidor