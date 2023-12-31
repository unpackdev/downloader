// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract CoinXP is ERC20 {
    constructor() ERC20("CoinXP", "CXP") {
        _mint(msg.sender,300000000*10**18);
    }
}
