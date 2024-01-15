// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";

contract Dotz is ERC20 {
    constructor(uint256 initialSupply) ERC20("Dotz", "DOTZ") {
        _mint(msg.sender, initialSupply);
    }
}