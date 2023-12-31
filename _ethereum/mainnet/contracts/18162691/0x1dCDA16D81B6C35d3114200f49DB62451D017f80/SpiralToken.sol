// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract SpiralToken is ERC20 {
    constructor() ERC20("Spiral Coin", "SPIRAL") {
        _mint(msg.sender, 100000000000 * 10**8);
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}
