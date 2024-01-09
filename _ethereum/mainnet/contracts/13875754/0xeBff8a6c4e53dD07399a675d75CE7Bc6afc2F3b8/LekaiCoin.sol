// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract LekaiCoin is ERC20 {
    // wei
    constructor(uint256 initial_supply) ERC20("LekaiCoin", "LKC") {
        _mint(msg.sender, initial_supply);
    }
}
