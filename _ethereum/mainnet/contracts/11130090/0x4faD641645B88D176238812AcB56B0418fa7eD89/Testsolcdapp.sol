// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20.sol";

contract Testsolcdapp is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Dapp Gold", "DGLD") {
        _mint(msg.sender, initialSupply); // money never sleeps pal...
    }
}
