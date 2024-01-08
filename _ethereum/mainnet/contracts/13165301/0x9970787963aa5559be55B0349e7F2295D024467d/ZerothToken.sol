// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";

contract ZerothToken is ERC20Burnable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}
