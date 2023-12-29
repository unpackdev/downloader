// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Order {

    struct Aggregate {
        uint256 expiry;
        address taker_address;
        address[] maker_addresses;
        uint256[] maker_nonces;
        address[][] taker_tokens;
        address[][] maker_tokens;
        uint256[][] taker_amounts;
        uint256[][] maker_amounts;
        address receiver;
        bytes commands;
    }

    struct Partial {
        uint256 expiry;
        address taker_address;
        address maker_address;
        uint256 maker_nonce;
        address[] taker_tokens;
        address[] maker_tokens;
        uint256[] taker_amounts;
        uint256[] maker_amounts;
        address receiver;
        bytes commands;
    }

}
