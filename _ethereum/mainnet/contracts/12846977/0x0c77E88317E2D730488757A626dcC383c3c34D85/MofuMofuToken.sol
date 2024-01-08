// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract MofuMofuToken is ERC20 {
    constructor() ERC20("MofuMofuToken", "MMT2") {
        _mint(msg.sender, 222222222222 * 10 ** decimals());
    }
}