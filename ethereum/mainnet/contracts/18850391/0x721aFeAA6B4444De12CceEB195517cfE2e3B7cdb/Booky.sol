// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract Booky is ERC20, ERC20Permit {

    address private owner;

    constructor() ERC20("Booky", "BOOKY") ERC20Permit("Booky") {
        owner = 0x96064ba777Af98F272e4C78e380b944F2742f0c5;
        uint256 initialSupply = 888_000_000 * (10 ** uint256(decimals())); // Initial supply to 888 million tokens
        _mint(owner, initialSupply);
    }
}
