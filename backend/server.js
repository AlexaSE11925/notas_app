const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
const PORT = 3000;
const SECRET = 'clave_secreta_notas_app';

app.use(cors());
app.use(express.json());

let usuarios = [];
let notas = [];
let siguienteNotaId = 1;

function verificarToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      mensaje: 'Token requerido',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const datos = jwt.verify(token, SECRET);
    req.usuario = datos;
    next();
  } catch (error) {
    return res.status(401).json({
      mensaje: 'Token inválido',
    });
  }
}

app.get('/', (req, res) => {
  res.json({
    mensaje: 'API de notas funcionando',
  });
});

app.post('/auth/register', async (req, res) => {
  const { correo, password } = req.body;

  if (!correo || !password) {
    return res.status(400).json({
      mensaje: 'Correo y contraseña son obligatorios',
    });
  }

  const existe = usuarios.find(
    (usuario) => usuario.correo === correo
  );

  if (existe) {
    return res.status(400).json({
      mensaje: 'El usuario ya existe',
    });
  }

  const passwordEncriptada = await bcrypt.hash(password, 10);

  const nuevoUsuario = {
    id: usuarios.length + 1,
    correo,
    password: passwordEncriptada,
  };

  usuarios.push(nuevoUsuario);

  res.status(201).json({
    mensaje: 'Usuario registrado correctamente',
  });
});

app.post('/auth/login', async (req, res) => {
  const { correo, password } = req.body;

  const usuario = usuarios.find(
    (u) => u.correo === correo
  );

  if (!usuario) {
    return res.status(401).json({
      mensaje: 'Credenciales incorrectas',
    });
  }

  const passwordValida = await bcrypt.compare(
    password,
    usuario.password
  );

  if (!passwordValida) {
    return res.status(401).json({
      mensaje: 'Credenciales incorrectas',
    });
  }

  const token = jwt.sign(
    {
      id: usuario.id,
      correo: usuario.correo,
    },
    SECRET,
    {
      expiresIn: '2h',
    }
  );

  res.json({
    mensaje: 'Inicio de sesión exitoso',
    token,
  });
});

app.get('/notas', verificarToken, (req, res) => {
  const notasUsuario = notas.filter(
    (nota) => nota.usuarioId === req.usuario.id
  );

  res.json(notasUsuario);
});

app.post('/notas', verificarToken, (req, res) => {
  const { titulo, contenido } = req.body;

  if (!titulo) {
    return res.status(400).json({
      mensaje: 'El título es obligatorio',
    });
  }

  const nuevaNota = {
    id: siguienteNotaId++,
    titulo,
    contenido: contenido || '',
    usuarioId: req.usuario.id,
    fecha: new Date().toISOString(),
  };

  notas.push(nuevaNota);

  res.status(201).json(nuevaNota);
});

app.put('/notas/:id', verificarToken, (req, res) => {
  const id = parseInt(req.params.id);

  const nota = notas.find(
    (n) =>
      n.id === id &&
      n.usuarioId === req.usuario.id
  );

  if (!nota) {
    return res.status(404).json({
      mensaje: 'Nota no encontrada',
    });
  }

  nota.titulo = req.body.titulo ?? nota.titulo;
  nota.contenido = req.body.contenido ?? nota.contenido;

  res.json(nota);
});

app.delete('/notas/:id', verificarToken, (req, res) => {
  const id = parseInt(req.params.id);

  const indice = notas.findIndex(
    (n) =>
      n.id === id &&
      n.usuarioId === req.usuario.id
  );

  if (indice === -1) {
    return res.status(404).json({
      mensaje: 'Nota no encontrada',
    });
  }

  notas.splice(indice, 1);

  res.json({
    mensaje: 'Nota eliminada correctamente',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor funcionando en http://localhost:${PORT}`);
});