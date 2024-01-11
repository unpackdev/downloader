// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract GOBToken is ERC20 {
    constructor() ERC20("God of Birds", "GOB") {
        _mint(msg.sender, 999_999_999_999_999 * 1e18);
    }
}