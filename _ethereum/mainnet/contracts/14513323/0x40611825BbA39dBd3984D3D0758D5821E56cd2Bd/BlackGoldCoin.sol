// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract BlackGoldCoin is ERC20 {
    constructor() ERC20("Black Gold Coin", "BGC") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
