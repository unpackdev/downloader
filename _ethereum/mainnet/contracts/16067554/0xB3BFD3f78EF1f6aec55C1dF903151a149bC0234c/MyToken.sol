// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract PREHIRO is ERC20 {
    constructor(address owner) ERC20("PREHIRO", "PREHIRO") {
        _mint(owner, 100000000 * 10 ** decimals());
    }
}