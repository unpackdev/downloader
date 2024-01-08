// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TestOCG is ERC20 {
    constructor(address owner) ERC20("Test OCG", "tOCG") {
        _mint(owner, 10000e18);
    }
}