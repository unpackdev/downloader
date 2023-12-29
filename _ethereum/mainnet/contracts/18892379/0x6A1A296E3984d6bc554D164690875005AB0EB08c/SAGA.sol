// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";

contract SAGA is ERC20 {

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }

}