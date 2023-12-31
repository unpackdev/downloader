// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./ERC20.sol";

contract EMCToken is ERC20 {
    constructor(uint256 _initialSupply) ERC20("EdgeMatrix Computing network", "EMC") {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }
}