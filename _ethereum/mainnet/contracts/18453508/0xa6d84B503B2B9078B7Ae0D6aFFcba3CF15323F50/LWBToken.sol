// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract LWBToken is ERC20 {
    constructor() ERC20("LWB", "LWB") {
        _mint(msg.sender, 49000000 * (10 ** uint256(decimals())));
    }
}