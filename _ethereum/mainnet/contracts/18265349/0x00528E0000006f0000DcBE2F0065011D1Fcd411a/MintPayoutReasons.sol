// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

bytes4 constant MINT_REFERRAL_REASON = bytes4(keccak256("MINT_REFERRAL"));
bytes4 constant PROTOCOL_FEE_REASON = bytes4(keccak256("PROTOCOL_FEE"));
bytes4 constant PURCHASE_AMOUNT_REASON = bytes4(keccak256("PURCHASE_AMOUNT"));
