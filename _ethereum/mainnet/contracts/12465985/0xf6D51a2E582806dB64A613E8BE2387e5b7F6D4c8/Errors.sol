// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

// Contains error code strings

library Errors {
  string public constant INVALID_AUCTION_TIMESTAMPS = '1';
  string public constant INVALID_BID_TIMESTAMPS = '2';
  string public constant INVALID_BID_AMOUNT = '3';
  string public constant AUCTION_ONGOING = '4';
  string public constant VALID_BIDDER = '5';
  string public constant NONEXISTANT_VAULT = '6';
  string public constant INVALID_DISTRIBUTION_BPS = '7';
  string public constant AUCTION_EXISTS = '8';
  string public constant NOT_STAKING_AUCTION = '9';
  string public constant INVALID_CALL_TYPE = '10';
  string public constant INVALID_AUCTION_DURATION = '11';
  string public constant INVALID_BIDDER = '12';
  string public constant PAUSED = '13';
  string public constant NOT_ADMIN = '14';
  string public constant INVALID_INIT_PARAMS = '15';
  string public constant INVALID_DISTRIBUTION_COUNT = '16';
  string public constant ZERO_RECIPIENT = '17';
  string public constant ZERO_CURRENCY = '18';
  string public constant RA_NOT_OUTBID = '19';
  string public constant RA_OUTBID = '20';
  string public constant RA_CLAIMED = '21';
  string public constant NO_DISTRIBUTIONS = '22';
  string public constant VAULT_ARRAY_MISMATCH = '23';
  string public constant CURRENCY_NOT_WHITELSITED = '24';
  string public constant NOT_NFT_OWNER = '25';
  string public constant ZERO_NFT = '26';
  string public constant NOT_COLLECTION_CREATOR = '27';
  string public constant INVALID_BUY_NOW = '28';
  string public constant INVALID_RESERVE_PRICE = '29';
}
