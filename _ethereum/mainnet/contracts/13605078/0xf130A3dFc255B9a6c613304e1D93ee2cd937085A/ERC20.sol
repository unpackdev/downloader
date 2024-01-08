// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("","") {
        _mint(msg.sender, 1e20);
    }
}