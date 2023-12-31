// SPDX-License-Identifier: MIT
// @author: https://github.com/goldnite
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("REMI BABY", "LUV") {
        _mint(msg.sender, 3_333_333_333_333_333_333_333_333);
    }
}
