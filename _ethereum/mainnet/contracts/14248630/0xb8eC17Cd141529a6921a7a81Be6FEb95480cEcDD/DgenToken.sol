// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
contract DgenToken is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        super._mint(msg.sender, 10000000 * (10**18));
    }
}
