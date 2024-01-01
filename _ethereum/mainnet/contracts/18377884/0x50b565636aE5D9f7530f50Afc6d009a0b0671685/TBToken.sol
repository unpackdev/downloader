// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TBToken is ERC20 {
    constructor() ERC20("TBTest", "TBT") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}