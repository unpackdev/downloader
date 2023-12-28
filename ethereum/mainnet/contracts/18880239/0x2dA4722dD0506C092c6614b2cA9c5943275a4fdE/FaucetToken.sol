// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract FaucetToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }
}
