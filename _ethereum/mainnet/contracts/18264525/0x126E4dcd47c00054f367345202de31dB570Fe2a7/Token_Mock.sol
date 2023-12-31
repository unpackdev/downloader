// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token_Mock is ERC20 {
    constructor() ERC20("MockToken", "MCKT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
