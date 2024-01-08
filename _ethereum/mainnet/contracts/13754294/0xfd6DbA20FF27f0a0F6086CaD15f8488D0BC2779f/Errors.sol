// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;


// Contains error code strings

library Errors {
  string public constant INVALID_AUCTION_PARAMS = 'INVALID_AUCTION_PARAMS';
  string public constant INVALID_ETHER_AMOUNT = 'INVALID_ETHER_AMOUNT';
  string public constant AUCTION_EXISTS = 'AUCTION_EXISTS';
  string public constant AUCTION_NOT_FINISHED = 'AUCTION_NOT_FINISHED';
  string public constant AUCTION_FINISHED = 'AUCTION_FINISHED';
  string public constant SMALL_BID_AMOUNT = 'SMALL_BID_AMOUNT';
  string public constant PAUSED = 'PAUSED';
  string public constant NO_RIGHTS = 'NO_RIGHTS';
  string public constant NOT_ADMIN = 'NOT_ADMIN';
  string public constant NOT_OWNER = 'NOT_OWNER';
  string public constant NOT_EXISTS = 'NOT_EXISTS';
  string public constant EMPTY_WINNER = 'EMPTY_WINNER';
  string public constant AUCTION_ALREADY_STARTED = 'AUCTION_ALREADY_STARTED';
  string public constant AUCTION_NOT_EXISTS = 'AUCTION_NOT_EXISTS';
  string public constant ZERO_ADDRESS = 'ZERO_ADDRESS';
  string public constant CANT_BID_TOKEN_AUCTION_BY_ETHER = 'CANT_BID_TOKEN_AUCTION_BY_ETHER';
  string public constant CANT_BID_ETHER_AUCTION_BY_TOKENS = 'CANT_BID_ETHER_AUCTION_BY_TOKENS';
  string public constant EMPTY_METADATA = 'EMPTY_METADATA';
}
