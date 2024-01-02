// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";

contract PIXEL is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply_);
    }
}
