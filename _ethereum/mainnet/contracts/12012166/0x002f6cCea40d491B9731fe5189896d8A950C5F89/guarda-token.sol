// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Burnable.sol";

contract GuardaToken is ERC20Burnable {
    constructor(uint256 initialSupply) public ERC20("Guarda Token", "GRD") {
        _setupDecimals(8);
        _mint(msg.sender, initialSupply);
    }
}