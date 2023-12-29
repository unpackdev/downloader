// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

//https://twitter.com/analysoor
contract WHEN is ERC20 {
    constructor() ERC20("WHEN", "WHEN") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}
