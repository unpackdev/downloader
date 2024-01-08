// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

library Errors {
    string public constant NOT_NFT_OWNER = '1';
    string public constant ZERO_CREATOR = '2';
    string public constant INVALID_BPS = '3';
    string public constant INVALID_SIGNATURE = '4';
    string public constant SIGNATURE_EXPIRED = '5';
    string public constant ZERO_SPENDER = '6';
    string public constant NOT_CREATOR = '7';
    string public constant ZERO_FEE_RECIPIENT = '8';
    string public constant ARRAY_MISMATCH = '9';
    string public constant INVALID_BATCH_MINT_AMOUNT = '10';
}
