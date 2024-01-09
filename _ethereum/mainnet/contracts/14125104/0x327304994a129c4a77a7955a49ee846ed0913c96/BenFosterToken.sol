// contracts/BenFosterToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract BenFosterToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("BenFosterToken", "BFT") {
        _mint(msg.sender, initialSupply);
    }
}
