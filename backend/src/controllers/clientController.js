const clients=require('../repositories/clientRepository');
const {validateClient}=require('../services/validationService');
const {CLIENT_TYPES}=require('../models/constants');
async function list(req,res){res.render('clients/index',{title:'Clientes',clients:await clients.findAll(),message:req.query.message});}
function newForm(req,res){res.render('clients/form',{title:'Nuevo cliente',client:{},types:CLIENT_TYPES,errors:[]});}
async function editForm(req,res){const client=await clients.findById(req.params.id); if(!client)return res.sendStatus(404); res.render('clients/form',{title:'Editar cliente',client,types:CLIENT_TYPES,errors:[]});}
async function create(req,res){const {data,errors}=validateClient(req.body); if(errors.length)return res.status(422).render('clients/form',{title:'Nuevo cliente',client:data,types:CLIENT_TYPES,errors}); await clients.create(data); res.redirect('/clients?message=Cliente creado');}
async function update(req,res){const {data,errors}=validateClient(req.body); data.id=req.params.id; if(errors.length)return res.status(422).render('clients/form',{title:'Editar cliente',client:data,types:CLIENT_TYPES,errors}); if(!await clients.update(req.params.id,data))return res.sendStatus(404); res.redirect('/clients?message=Cliente actualizado');}
async function remove(req,res){try{if(!await clients.remove(req.params.id))return res.sendStatus(404); res.redirect('/clients?message=Cliente eliminado');}catch(e){if(e.code==='23503')return res.redirect('/clients?message=No se puede eliminar: tiene coberturas asociadas'); throw e;}}
module.exports={list,newForm,editForm,create,update,remove};
