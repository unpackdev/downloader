// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";

contract SiphonToken is ERC20 {
    constructor(address to, uint256 amount) ERC20("ChefSiphon", "ChefSiphon") {
        _mint(to, amount);
    }
}
