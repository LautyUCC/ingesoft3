const clients = require('../repositories/clientRepository');
const { validateClient } = require('../services/validationService');

async function list(req, res) {
  res.json(await clients.findAll());
}

async function show(req, res) {
  const client = await clients.findById(req.params.id);
  if (!client) return res.sendStatus(404);
  res.json(client);
}

async function create(req, res) {
  const { data, errors } = validateClient(req.body);
  if (errors.length) return res.status(400).json({ errors });
  const client = await clients.create(data);
  res.status(201).location(`/api/clients/${client.id}`).json(client);
}

async function update(req, res) {
  const { data, errors } = validateClient(req.body);
  if (errors.length) return res.status(400).json({ errors });
  const client = await clients.update(req.params.id, data);
  if (!client) return res.sendStatus(404);
  res.json(client);
}

async function remove(req, res) {
  try {
    if (!await clients.remove(req.params.id)) return res.sendStatus(404);
    res.sendStatus(204);
  } catch (error) {
    if (error.code === '23503') return res.status(409).json({ error: 'El cliente tiene coberturas' });
    throw error;
  }
}

module.exports = { list, show, create, update, remove };
