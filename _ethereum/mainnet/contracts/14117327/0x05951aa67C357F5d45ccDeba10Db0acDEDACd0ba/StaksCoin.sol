// SPDX-License-Identifier: UNLICENSED
// Copyright 2022, Cyber Secure Mobile Payments, Inc.
// Staks, StaksPay and StaksMusician and the Staks logo are
// trademarks of Cyber Secure Mobile Payments, Inc.

pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract StaksCoin is ERC20, ERC20Burnable {
    constructor() ERC20("StaksCoin", "STAKS") {
        _mint(msg.sender, 20 * 10**9 * 10**decimals());
    }
}
