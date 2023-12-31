// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

enum CurveErrorCode {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0 or too large
    BASE_PRICE_OVERFLOW, // The updated base price doesn't fit into 128 bits
    SELL_NOT_SUPPORTED, // The pool doesn't support sell
    BUY_NOT_SUPPORTED, // The pool doesn't support buy
    MISSING_SWAP_DATA, // No swap data provided for a pool that requires it
    NOOP // No operation was performed
}
