
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";

contract NFTism is ERC20 {
    constructor() ERC20("NFTism", "NFTism") {
        _mint(msg.sender, 10_000_000 * 10**uint(decimals()));
    }
}