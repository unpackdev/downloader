// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DoggoCoin is ERC20 {
    constructor() ERC20("DoggoCoin", "DOGGO") {
        // Start supply with 6.942 trillion tokens.
        _mint(msg.sender, 6942000000000 * 10**decimals());
    }
}