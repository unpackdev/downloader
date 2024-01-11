// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract MFTest is ERC20 {
    constructor() ERC20("MFTest", "MFT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}