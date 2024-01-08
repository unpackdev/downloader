// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CubeverseToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 amountToMint
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, amountToMint);
    }
}
