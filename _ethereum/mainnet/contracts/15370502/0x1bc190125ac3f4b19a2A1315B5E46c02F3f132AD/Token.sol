// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

contract Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20 (name_, symbol_) {
        _mint(msg.sender, totalSupply_ * 10**(decimals()));
    }
}