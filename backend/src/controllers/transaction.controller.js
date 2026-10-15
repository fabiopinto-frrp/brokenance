import * as transactionService from '../services/transaction.service.js';
import { toTransactionListResponse, toTransactionResponse } from '../views/transaction.view.js';

export async function list(req, res) {
  res.json(toTransactionListResponse(await transactionService.list(req.userId, req.query)));
}

export async function create(req, res) {
  const transaction = await transactionService.create(req.userId, req.body);
  res.status(201).json(toTransactionResponse(transaction));
}

export async function update(req, res) {
  const transaction = await transactionService.update(req.userId, req.params.id, req.body);
  res.json(toTransactionResponse(transaction));
}

export async function remove(req, res) {
  await transactionService.remove(req.userId, req.params.id);
  res.status(204).end();
}
