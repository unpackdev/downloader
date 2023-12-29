// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./console.sol";
import "./ERC20.sol";

contract Erc20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        address account_,
        uint256 amount_
    ) ERC20(name_, symbol_) {
        _mint(account_, amount_ * 10**18);
    }
}
